
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


(define-public (claim-funds (campaign-id uint))
    (let
        (
            (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) 
                     ERR-INVALID-CAMPAIGN))
        )
        (asserts! (is-valid-campaign campaign-id) ERR-INVALID-CAMPAIGN)
        (asserts! (is-eq tx-sender (get owner campaign)) ERR-NOT-AUTHORIZED)
        (asserts! (>= (get total-raised campaign) (get goal campaign)) ERR-GOAL-NOT-MET)
        (asserts! (not (get claimed campaign)) ERR-ALREADY-CLAIMED)

        (try! (as-contract (stx-transfer? 
            (get total-raised campaign) 
            tx-sender 
            (get owner campaign))))

        (map-set campaigns
            { campaign-id: campaign-id }
            (merge campaign { claimed: true, status: "completed" })
        )
        (ok true)
    )
)


(define-public (refund (campaign-id uint))
    (let
        (
            (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) 
                     ERR-INVALID-CAMPAIGN))
            (contribution (unwrap! (map-get? contributions 
                { campaign-id: campaign-id, contributor: tx-sender }) 
                ERR-NOT-AUTHORIZED))
        )
        (asserts! (is-valid-campaign campaign-id) ERR-INVALID-CAMPAIGN)
        (asserts! (> stacks-block-height (get deadline campaign)) ERR-DEADLINE-PASSED)
        (asserts! (< (get total-raised campaign) (get goal campaign)) ERR-GOAL-NOT-MET)

        (try! (as-contract (stx-transfer? 
            (get amount contribution) 
            tx-sender 
            tx-sender)))

        (map-delete contributions { campaign-id: campaign-id, contributor: tx-sender })
        (ok true)
    )
)


(define-read-only (get-campaign-status (campaign-id uint))
    (let
        (
            (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id })
                     ERR-INVALID-CAMPAIGN))
        )
        (ok {
            owner: (get owner campaign),
            goal: (get goal campaign),
            total-raised: (get total-raised campaign),
            remaining-blocks: (- (get deadline campaign) stacks-block-height),
            progress-percentage: (/ (* (get total-raised campaign) u100) (get goal campaign)),
            is-active: (< stacks-block-height (get deadline campaign)),
            is-successful: (>= (get total-raised campaign) (get goal campaign)),
            is-claimed: (get claimed campaign)
        })
    )
)


(define-public (update-deadline (campaign-id uint) (new-deadline uint))
    (let
        (
            (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id })
                     ERR-INVALID-CAMPAIGN))
        )
        (asserts! (is-valid-campaign campaign-id) ERR-INVALID-CAMPAIGN)
        (asserts! (is-eq tx-sender (get owner campaign)) ERR-NOT-AUTHORIZED)
        (asserts! (> new-deadline stacks-block-height) ERR-INVALID-DEADLINE)
        (asserts! (> new-deadline (get deadline campaign)) ERR-INVALID-DEADLINE)

        (map-set campaigns
            { campaign-id: campaign-id }
            (merge campaign { deadline: new-deadline })
        )
        (ok true)
    )
)


(define-read-only (get-contribution-history (campaign-id uint) (contributor principal))
    (let
        (
            (contribution (unwrap! (map-get? contributions 
                { campaign-id: campaign-id, contributor: contributor })
                ERR-NO-CONTRIBUTION))
        )
        (ok {
            amount: (get amount contribution),
            timestamp: (get timestamp contribution),
            campaign-id: campaign-id
        })
    )
)


(define-public (cancel-campaign (campaign-id uint))
    (let
        (
            (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id })
                     ERR-INVALID-CAMPAIGN))
        )
        (asserts! (is-valid-campaign campaign-id) ERR-INVALID-CAMPAIGN)
        (asserts! (is-eq tx-sender (get owner campaign)) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get total-raised campaign) u0) ERR-CAMPAIGN-ACTIVE)

        (map-set campaigns
            { campaign-id: campaign-id }
            (merge campaign { 
                status: "cancelled",
                deadline: stacks-block-height
            })
        )
        (ok true)
    )
)
