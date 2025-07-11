;; Sharing Schedule Contract
;; Organizes community extension cord lending and availability

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u400))
(define-constant ERR_CORD_NOT_FOUND (err u401))
(define-constant ERR_RESERVATION_CONFLICT (err u402))
(define-constant ERR_INVALID_TIME_RANGE (err u403))
(define-constant ERR_RESERVATION_NOT_FOUND (err u404))
(define-constant ERR_PAST_RESERVATION (err u405))

;; Priority levels
(define-constant PRIORITY_LOW u1)
(define-constant PRIORITY_NORMAL u2)
(define-constant PRIORITY_HIGH u3)
(define-constant PRIORITY_EMERGENCY u4)

;; Data Variables
(define-data-var next-reservation-id uint u1)
(define-data-var community-reputation-threshold uint u50)
(define-data-var max-reservation-duration uint u604800) ;; 7 days in seconds

;; Data Maps
(define-map cord-availability
  { cord-id: uint }
  {
    owner: principal,
    is-shareable: bool,
    availability-schedule: (list 7 bool), ;; Days of week availability
    hourly-restrictions: (list 24 bool), ;; Hours of day restrictions
    max-loan-duration: uint,
    current-borrower: (optional principal)
  }
)

(define-map reservations
  { reservation-id: uint }
  {
    cord-id: uint,
    borrower: principal,
    start-time: uint,
    end-time: uint,
    priority-level: uint,
    purpose: (string-ascii 200),
    status: (string-ascii 20), ;; "pending", "confirmed", "active", "completed", "cancelled"
    created-at: uint
  }
)

(define-map user-reputation
  { user: principal }
  {
    total-loans: uint,
    successful-returns: uint,
    late-returns: uint,
    reputation-score: uint,
    is-trusted: bool
  }
)

(define-map schedule-conflicts
  { cord-id: uint, time-slot: uint }
  {
    conflicting-reservations: (list 10 uint),
    resolution-method: (string-ascii 50),
    resolved: bool
  }
)

(define-map community-calendar
  { date: uint }
  {
    total-reservations: uint,
    high-priority-count: uint,
    available-cords: uint,
    community-events: (list 5 (string-ascii 100))
  }
)

;; Public Functions

;; Register cord for sharing
(define-public (register-shareable-cord
  (cord-id uint)
  (availability-days (list 7 bool))
  (hourly-restrictions (list 24 bool))
  (max-duration uint))
  (begin
    (map-set cord-availability
      { cord-id: cord-id }
      {
        owner: tx-sender,
        is-shareable: true,
        availability-schedule: availability-days,
        hourly-restrictions: hourly-restrictions,
        max-loan-duration: max-duration,
        current-borrower: none
      }
    )
    (ok true)
  )
)

;; Create reservation request
(define-public (create-reservation
  (cord-id uint)
  (start-time uint)
  (end-time uint)
  (priority-level uint)
  (purpose (string-ascii 200)))
  (let ((reservation-id (var-get next-reservation-id)))
    (asserts! (> end-time start-time) ERR_INVALID_TIME_RANGE)
    (asserts! (> start-time block-height) ERR_PAST_RESERVATION)
    (asserts! (<= (- end-time start-time) (var-get max-reservation-duration)) ERR_INVALID_TIME_RANGE)
    (asserts! (check-availability cord-id start-time end-time) ERR_RESERVATION_CONFLICT)

    (map-set reservations
      { reservation-id: reservation-id }
      {
        cord-id: cord-id,
        borrower: tx-sender,
        start-time: start-time,
        end-time: end-time,
        priority-level: priority-level,
        purpose: purpose,
        status: "pending",
        created-at: block-height
      }
    )
    (var-set next-reservation-id (+ reservation-id u1))
    (ok reservation-id)
  )
)

;; Confirm reservation
(define-public (confirm-reservation (reservation-id uint))
  (let ((reservation (unwrap! (map-get? reservations { reservation-id: reservation-id }) ERR_RESERVATION_NOT_FOUND)))
    (let ((cord-availability-data (unwrap! (map-get? cord-availability { cord-id: (get cord-id reservation) }) ERR_CORD_NOT_FOUND)))
      (asserts! (is-eq tx-sender (get owner cord-availability-data)) ERR_UNAUTHORIZED)
      (asserts! (is-eq (get status reservation) "pending") ERR_UNAUTHORIZED)

      ;; Update reservation status
      (map-set reservations
        { reservation-id: reservation-id }
        (merge reservation { status: "confirmed" })
      )

      ;; Update cord availability
      (map-set cord-availability
        { cord-id: (get cord-id reservation) }
        (merge cord-availability-data { current-borrower: (some (get borrower reservation)) })
      )
      (ok true)
    )
  )
)

;; Start active loan
(define-public (start-loan (reservation-id uint))
  (let ((reservation (unwrap! (map-get? reservations { reservation-id: reservation-id }) ERR_RESERVATION_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get borrower reservation)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status reservation) "confirmed") ERR_UNAUTHORIZED)
    (asserts! (>= block-height (get start-time reservation)) ERR_UNAUTHORIZED)

    (map-set reservations
      { reservation-id: reservation-id }
      (merge reservation { status: "active" })
    )
    (ok true)
  )
)

;; Complete loan and return cord
(define-public (complete-loan (reservation-id uint))
  (let ((reservation (unwrap! (map-get? reservations { reservation-id: reservation-id }) ERR_RESERVATION_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get borrower reservation)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status reservation) "active") ERR_UNAUTHORIZED)

    ;; Update reservation status
    (map-set reservations
      { reservation-id: reservation-id }
      (merge reservation { status: "completed" })
    )

    ;; Release cord availability
    (let ((cord-availability-data (unwrap! (map-get? cord-availability { cord-id: (get cord-id reservation) }) ERR_CORD_NOT_FOUND)))
      (map-set cord-availability
        { cord-id: (get cord-id reservation) }
        (merge cord-availability-data { current-borrower: none })
      )
    )

    ;; Update user reputation
    (update-user-reputation (get borrower reservation) true (<= block-height (get end-time reservation)))
    (ok true)
  )
)

;; Cancel reservation
(define-public (cancel-reservation (reservation-id uint))
  (let ((reservation (unwrap! (map-get? reservations { reservation-id: reservation-id }) ERR_RESERVATION_NOT_FOUND)))
    (asserts! (or
      (is-eq tx-sender (get borrower reservation))
      (is-eq tx-sender CONTRACT_OWNER)) ERR_UNAUTHORIZED)

    (map-set reservations
      { reservation-id: reservation-id }
      (merge reservation { status: "cancelled" })
    )
    (ok true)
  )
)

;; Resolve scheduling conflict
(define-public (resolve-conflict
  (cord-id uint)
  (time-slot uint)
  (resolution-method (string-ascii 50)))
  (let ((conflict (unwrap! (map-get? schedule-conflicts { cord-id: cord-id, time-slot: time-slot }) ERR_RESERVATION_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set schedule-conflicts
      { cord-id: cord-id, time-slot: time-slot }
      (merge conflict {
        resolution-method: resolution-method,
        resolved: true
      })
    )
    (ok true)
  )
)

;; Private Functions

;; Check availability for time range
(define-private (check-availability (cord-id uint) (start-time uint) (end-time uint))
  (let ((availability (map-get? cord-availability { cord-id: cord-id })))
    (match availability
      avail (and
        (get is-shareable avail)
        (is-none (get current-borrower avail))
        (check-time-slot-availability cord-id start-time end-time))
      false
    )
  )
)

;; Check specific time slot availability
(define-private (check-time-slot-availability (cord-id uint) (start-time uint) (end-time uint))
  ;; Simplified check - in practice would check against all existing reservations
  true
)

;; Update user reputation
(define-private (update-user-reputation (user principal) (returned bool) (on-time bool))
  (let ((reputation (default-to
    { total-loans: u0, successful-returns: u0, late-returns: u0, reputation-score: u50, is-trusted: false }
    (map-get? user-reputation { user: user }))))
    (let (
      (new-total (+ (get total-loans reputation) u1))
      (new-successful (if returned (+ (get successful-returns reputation) u1) (get successful-returns reputation)))
      (new-late (if (and returned (not on-time)) (+ (get late-returns reputation) u1) (get late-returns reputation)))
    )
      (let ((new-score (calculate-reputation-score new-total new-successful new-late)))
        (map-set user-reputation
          { user: user }
          {
            total-loans: new-total,
            successful-returns: new-successful,
            late-returns: new-late,
            reputation-score: new-score,
            is-trusted: (>= new-score (var-get community-reputation-threshold))
          }
        )
      )
    )
  )
)

;; Calculate reputation score
(define-private (calculate-reputation-score (total uint) (successful uint) (late uint))
  (if (is-eq total u0)
    u50
    (let ((success-rate (/ (* successful u100) total)))
      (if (> late u0)
        (- success-rate (* late u5)) ;; Penalty for late returns
        success-rate
      )
    )
  )
)

;; Read-only Functions

;; Get cord availability
(define-read-only (get-cord-availability (cord-id uint))
  (map-get? cord-availability { cord-id: cord-id })
)

;; Get reservation details
(define-read-only (get-reservation (reservation-id uint))
  (map-get? reservations { reservation-id: reservation-id })
)

;; Get user reputation
(define-read-only (get-user-reputation (user principal))
  (map-get? user-reputation { user: user })
)

;; Check if cord is available for time range
(define-read-only (is-cord-available (cord-id uint) (start-time uint) (end-time uint))
  (check-availability cord-id start-time end-time)
)

;; Get available cords for time range
(define-read-only (get-available-cords (start-time uint) (end-time uint))
  ;; Return list of available cord IDs for the time range
  (list u1 u2 u3) ;; Simplified response
)

;; Get user's active reservations
(define-read-only (get-user-reservations (user principal))
  ;; Return list of reservation IDs for the user
  (list u1 u2) ;; Simplified response
)

;; Get community calendar for date
(define-read-only (get-community-calendar (date uint))
  (map-get? community-calendar { date: date })
)

;; Get scheduling conflicts
(define-read-only (get-schedule-conflicts (cord-id uint) (time-slot uint))
  (map-get? schedule-conflicts { cord-id: cord-id, time-slot: time-slot })
)

;; Get reservation statistics
(define-read-only (get-reservation-stats)
  {
    total-reservations: (- (var-get next-reservation-id) u1),
    active-loans: u5, ;; Would calculate from active reservations
    completion-rate: u85, ;; Would calculate from completed vs total
    average-duration: u3600 ;; Would calculate average loan duration
  }
)
