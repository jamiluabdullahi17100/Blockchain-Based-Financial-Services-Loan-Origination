;; Credit Assessment Contract
;; Assesses borrower creditworthiness

(define-constant ERR_INVALID_SCORE (err u300))
(define-constant ERR_ASSESSMENT_EXISTS (err u301))
(define-constant ERR_UNAUTHORIZED (err u302))

;; Credit assessment data
(define-map credit-assessments uint {
    application-id: uint,
    borrower: principal,
    credit-score: uint,
    debt-to-income-ratio: uint,
    employment-status: (string-ascii 20),
    assessment-date: uint,
    risk-level: (string-ascii 10),
    recommended-rate: uint
})

;; Public functions
(define-public (assess-credit
    (application-id uint)
    (borrower principal)
    (credit-score uint)
    (debt-to-income-ratio uint)
    (employment-status (string-ascii 20)))
    (let ((risk-level (calculate-risk-level credit-score debt-to-income-ratio))
          (recommended-rate (calculate-recommended-rate credit-score debt-to-income-ratio)))

        (asserts! (and (>= credit-score u300) (<= credit-score u850)) ERR_INVALID_SCORE)
        (asserts! (<= debt-to-income-ratio u100) ERR_INVALID_SCORE)

        (map-set credit-assessments application-id {
            application-id: application-id,
            borrower: borrower,
            credit-score: credit-score,
            debt-to-income-ratio: debt-to-income-ratio,
            employment-status: employment-status,
            assessment-date: block-height,
            risk-level: risk-level,
            recommended-rate: recommended-rate
        })

        (ok { risk-level: risk-level, recommended-rate: recommended-rate })
    )
)

;; Private functions
(define-private (calculate-risk-level (credit-score uint) (debt-to-income uint))
    (if (and (>= credit-score u750) (<= debt-to-income u30))
        "low"
        (if (and (>= credit-score u650) (<= debt-to-income u45))
            "medium"
            "high"
        )
    )
)

(define-private (calculate-recommended-rate (credit-score uint) (debt-to-income uint))
    (if (>= credit-score u750)
        u350  ;; 3.5%
        (if (>= credit-score u700)
            u450  ;; 4.5%
            (if (>= credit-score u650)
                u650  ;; 6.5%
                u850  ;; 8.5%
            )
        )
    )
)

;; Read-only functions
(define-read-only (get-credit-assessment (application-id uint))
    (map-get? credit-assessments application-id)
)

(define-read-only (is-creditworthy (application-id uint))
    (match (map-get? credit-assessments application-id)
        assessment (not (is-eq (get risk-level assessment) "high"))
        false
    )
)
