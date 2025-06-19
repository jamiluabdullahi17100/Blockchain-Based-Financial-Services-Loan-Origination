;; Application Processing Contract
;; Handles loan application submissions and management

(define-constant ERR_INVALID_APPLICATION (err u200))
(define-constant ERR_APPLICATION_EXISTS (err u201))
(define-constant ERR_APPLICATION_NOT_FOUND (err u202))
(define-constant ERR_INVALID_AMOUNT (err u203))
(define-constant ERR_UNAUTHORIZED (err u204))

;; Data structures
(define-map loan-applications uint {
    borrower: principal,
    amount: uint,
    purpose: (string-ascii 100),
    term-months: uint,
    interest-rate-requested: uint,
    submission-date: uint,
    status: (string-ascii 20),
    credit-score: uint,
    annual-income: uint
})

(define-data-var next-application-id uint u1)

;; Public functions
(define-public (submit-application
    (amount uint)
    (purpose (string-ascii 100))
    (term-months uint)
    (interest-rate-requested uint)
    (annual-income uint))
    (let ((application-id (var-get next-application-id)))
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (asserts! (and (>= term-months u6) (<= term-months u360)) ERR_INVALID_APPLICATION)
        (asserts! (> annual-income u0) ERR_INVALID_APPLICATION)

        (map-set loan-applications application-id {
            borrower: tx-sender,
            amount: amount,
            purpose: purpose,
            term-months: term-months,
            interest-rate-requested: interest-rate-requested,
            submission-date: block-height,
            status: "submitted",
            credit-score: u0,
            annual-income: annual-income
        })

        (var-set next-application-id (+ application-id u1))
        (ok application-id)
    )
)

(define-public (update-application-status (application-id uint) (new-status (string-ascii 20)))
    (match (map-get? loan-applications application-id)
        application (begin
            (map-set loan-applications application-id
                (merge application { status: new-status }))
            (ok true)
        )
        ERR_APPLICATION_NOT_FOUND
    )
)

(define-public (update-credit-score (application-id uint) (credit-score uint))
    (match (map-get? loan-applications application-id)
        application (begin
            (map-set loan-applications application-id
                (merge application { credit-score: credit-score }))
            (ok true)
        )
        ERR_APPLICATION_NOT_FOUND
    )
)

;; Read-only functions
(define-read-only (get-application (application-id uint))
    (map-get? loan-applications application-id)
)

(define-read-only (get-next-application-id)
    (var-get next-application-id)
)
