
;; sBTC-CrowdForge

;; summary:
;; description:
;; Constants
(define-constant contract-owner tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-CAMPAIGN-EXISTS (err u101))
(define-constant ERR-INVALID-AMOUNT (err u102))
(define-constant ERR-DEADLINE-PASSED (err u103))
(define-constant ERR-GOAL-NOT-MET (err u104))
(define-constant ERR-ALREADY-CLAIMED (err u105))
(define-constant ERR-INVALID-CAMPAIGN (err u106))
(define-constant ERR-INVALID-DEADLINE (err u107))
(define-constant ERR-NO-CONTRIBUTION (err u108))
(define-constant ERR-CAMPAIGN-ACTIVE (err u109))


;; Data Maps
(define-map campaigns
    { campaign-id: uint }
    {
        owner: principal,
        goal: uint,
        deadline: uint,
        total-raised: uint,
        claimed: bool,
        status: (string-ascii 20),
        description: (optional (string-ascii 500))
    }
)


(define-map contributions
    { campaign-id: uint, contributor: principal }
    { amount: uint, timestamp: uint }
)

;; Campaign counter
(define-data-var campaign-counter uint u0)


;; Helper Functions
(define-private (is-valid-campaign (campaign-id uint))
    (is-some (map-get? campaigns { campaign-id: campaign-id }))
)


;; Public functions
(define-public (create-campaign (goal uint) (deadline uint))
    (let
        (
            (campaign-id (var-get campaign-counter))
        )
        (asserts! (> goal u0) ERR-INVALID-AMOUNT)
        (asserts! (> deadline stacks-block-height) ERR-DEADLINE-PASSED)
        (asserts! (not (is-valid-campaign campaign-id)) ERR-CAMPAIGN-EXISTS)

        (map-insert campaigns
            { campaign-id: campaign-id }
            {
                owner: tx-sender,
                goal: goal,
                deadline: deadline,
                total-raised: u0,
                claimed: false,
                status: "active",
                description: none
            }
        )
        (var-set campaign-counter (+ campaign-id u1))
        (ok campaign-id)
    )
)


(define-public (contribute (campaign-id uint) (amount uint))
    (let
        (
            (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) 
                     ERR-INVALID-CAMPAIGN))
            (current-total (get total-raised campaign))
        )
        (asserts! (is-valid-campaign campaign-id) ERR-INVALID-CAMPAIGN)
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (asserts! (< stacks-block-height (get deadline campaign)) ERR-DEADLINE-PASSED)

        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

        (map-set campaigns
            { campaign-id: campaign-id }
            (merge campaign { total-raised: (+ current-total amount) })
        )

        (map-set contributions
            { campaign-id: campaign-id, contributor: tx-sender }
            { 
                amount: (+ amount (default-to u0 
                    (get amount (map-get? contributions 
                        { campaign-id: campaign-id, contributor: tx-sender })))),
                timestamp: stacks-block-height
            }
        )
        (ok true)
    )
)
