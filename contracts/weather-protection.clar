;; Weather Protection Contract
;; Manages waterproof covering and storage during storms

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_CORD_NOT_FOUND (err u201))
(define-constant ERR_STORAGE_FULL (err u202))
(define-constant ERR_INVALID_WEATHER_DATA (err u203))
(define-constant ERR_PROTECTION_ACTIVE (err u204))

;; Weather severity levels
(define-constant WEATHER_CLEAR u0)
(define-constant WEATHER_LIGHT_RAIN u1)
(define-constant WEATHER_HEAVY_RAIN u2)
(define-constant WEATHER_STORM u3)
(define-constant WEATHER_SEVERE_STORM u4)

;; Data Variables
(define-data-var current-weather-level uint WEATHER_CLEAR)
(define-data-var emergency-mode bool false)
(define-data-var next-storage-id uint u1)

;; Data Maps
(define-map cord-protection
  { cord-id: uint }
  {
    waterproof-rating: uint,
    current-location: (string-ascii 100),
    is-protected: bool,
    protection-type: (string-ascii 50),
    last-weather-check: uint
  }
)

(define-map storage-locations
  { storage-id: uint }
  {
    name: (string-ascii 100),
    capacity: uint,
    current-occupancy: uint,
    weather-rating: uint,
    is-available: bool
  }
)

(define-map weather-alerts
  { alert-id: uint }
  {
    weather-level: uint,
    alert-time: uint,
    affected-area: (string-ascii 100),
    duration-estimate: uint,
    is-active: bool
  }
)

(define-map cord-storage-assignments
  { cord-id: uint }
  {
    storage-id: uint,
    stored-at: uint,
    retrieval-scheduled: uint,
    emergency-storage: bool
  }
)

;; Public Functions

;; Register cord for weather protection
(define-public (register-cord-protection
  (cord-id uint)
  (waterproof-rating uint)
  (location (string-ascii 100)))
  (begin
    (map-set cord-protection
      { cord-id: cord-id }
      {
        waterproof-rating: waterproof-rating,
        current-location: location,
        is-protected: false,
        protection-type: "none",
        last-weather-check: block-height
      }
    )
    (ok true)
  )
)

;; Add storage location
(define-public (add-storage-location
  (name (string-ascii 100))
  (capacity uint)
  (weather-rating uint))
  (let ((storage-id (var-get next-storage-id)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set storage-locations
      { storage-id: storage-id }
      {
        name: name,
        capacity: capacity,
        current-occupancy: u0,
        weather-rating: weather-rating,
        is-available: true
      }
    )
    (var-set next-storage-id (+ storage-id u1))
    (ok storage-id)
  )
)

;; Update weather conditions
(define-public (update-weather-level (new-level uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= new-level WEATHER_SEVERE_STORM) ERR_INVALID_WEATHER_DATA)
    (var-set current-weather-level new-level)
    ;; Trigger emergency mode for severe weather
    (if (>= new-level WEATHER_STORM)
      (var-set emergency-mode true)
      (var-set emergency-mode false)
    )
    (ok true)
  )
)

;; Activate protection for cord
(define-public (activate-protection (cord-id uint) (protection-type (string-ascii 50)))
  (let ((protection (unwrap! (map-get? cord-protection { cord-id: cord-id }) ERR_CORD_NOT_FOUND)))
    (map-set cord-protection
      { cord-id: cord-id }
      (merge protection {
        is-protected: true,
        protection-type: protection-type,
        last-weather-check: block-height
      })
    )
    (ok true)
  )
)

;; Store cord in weather-safe location
(define-public (store-cord-emergency (cord-id uint) (storage-id uint))
  (let (
    (storage (unwrap! (map-get? storage-locations { storage-id: storage-id }) ERR_CORD_NOT_FOUND))
    (protection (unwrap! (map-get? cord-protection { cord-id: cord-id }) ERR_CORD_NOT_FOUND))
  )
    (asserts! (< (get current-occupancy storage) (get capacity storage)) ERR_STORAGE_FULL)
    (asserts! (var-get emergency-mode) ERR_UNAUTHORIZED)

    ;; Update storage occupancy
    (map-set storage-locations
      { storage-id: storage-id }
      (merge storage {
        current-occupancy: (+ (get current-occupancy storage) u1)
      })
    )

    ;; Record storage assignment
    (map-set cord-storage-assignments
      { cord-id: cord-id }
      {
        storage-id: storage-id,
        stored-at: block-height,
        retrieval-scheduled: u0,
        emergency-storage: true
      }
    )

    ;; Update protection status
    (map-set cord-protection
      { cord-id: cord-id }
      (merge protection {
        is-protected: true,
        protection-type: "emergency-storage"
      })
    )
    (ok true)
  )
)

;; Schedule cord retrieval after weather clears
(define-public (schedule-retrieval (cord-id uint) (retrieval-time uint))
  (let ((assignment (unwrap! (map-get? cord-storage-assignments { cord-id: cord-id }) ERR_CORD_NOT_FOUND)))
    (map-set cord-storage-assignments
      { cord-id: cord-id }
      (merge assignment { retrieval-scheduled: retrieval-time })
    )
    (ok true)
  )
)

;; Check weather safety for cord usage
(define-public (check-weather-safety (cord-id uint))
  (let ((protection (unwrap! (map-get? cord-protection { cord-id: cord-id }) ERR_CORD_NOT_FOUND)))
    (let ((weather-level (var-get current-weather-level)))
      (if (and
            (<= weather-level WEATHER_LIGHT_RAIN)
            (>= (get waterproof-rating protection) weather-level))
        (ok true)
        (err u205) ;; Weather too severe for safe usage
      )
    )
  )
)

;; Read-only Functions

;; Get current weather level
(define-read-only (get-current-weather)
  (var-get current-weather-level)
)

;; Get emergency mode status
(define-read-only (is-emergency-mode)
  (var-get emergency-mode)
)

;; Get cord protection status
(define-read-only (get-protection-status (cord-id uint))
  (map-get? cord-protection { cord-id: cord-id })
)

;; Get storage location info
(define-read-only (get-storage-info (storage-id uint))
  (map-get? storage-locations { storage-id: storage-id })
)

;; Get available storage capacity
(define-read-only (get-available-storage)
  (fold check-storage-availability (list u1 u2 u3 u4 u5) u0)
)

;; Helper function for storage availability
(define-private (check-storage-availability (storage-id uint) (total-capacity uint))
  (match (map-get? storage-locations { storage-id: storage-id })
    storage (+ total-capacity (- (get capacity storage) (get current-occupancy storage)))
    total-capacity
  )
)

;; Get weather safety recommendation
(define-read-only (get-weather-recommendation (cord-id uint))
  (let (
    (protection (map-get? cord-protection { cord-id: cord-id }))
    (weather-level (var-get current-weather-level))
  )
    (match protection
      prot {
        weather-level: weather-level,
        safe-for-use: (<= weather-level (get waterproof-rating prot)),
        protection-needed: (> weather-level WEATHER_LIGHT_RAIN),
        emergency-storage-required: (>= weather-level WEATHER_STORM)
      }
      {
        weather-level: weather-level,
        safe-for-use: false,
        protection-needed: true,
        emergency-storage-required: true
      }
    )
  )
)
