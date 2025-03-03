;; Crowda - Crowdfunding Smart Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-amount (err u101))
(define-constant err-deadline-passed (err u102))
(define-constant err-campaign-not-found (err u103))
(define-constant err-goal-not-reached (err u104))
(define-constant err-already-claimed (err u105))
(define-constant err-insufficient-balance (err u106))
(define-constant err-invalid-deadline (err u107))
(define-constant err-contract-paused (err u108))

;; Campaign status
(define-data-var campaign-status-active uint u1)
(define-data-var campaign-status-ended uint u2)
(define-data-var campaign-status-claimed uint u3)

;; Contract status
(define-data-var contract-paused bool false)

;; Data structures
(define-map campaigns
    { campaign-id: uint }
    {
        owner: principal,
        goal: uint,
        deadline: uint,
        raised: uint,
        claimed: bool,
        status: uint
    }
)

(define-map contributions
    { campaign-id: uint, contributor: principal }
    { total-amount: uint }
)

;; Data variables
(define-data-var next-campaign-id uint u1)

;; Administrative functions
(define-public (set-contract-pause (paused bool))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (var-set contract-paused paused))
    )
)

;; Read-only functions
(define-read-only (get-campaign (campaign-id uint))
    (map-get? campaigns { campaign-id: campaign-id })
)

(define-read-only (get-contribution (campaign-id uint) (contributor principal))
    (map-get? contributions { campaign-id: campaign-id, contributor: contributor })
)

;; Create a new crowdfunding campaign
(define-public (create-campaign (goal uint) (deadline uint))
    (let
        (
            (campaign-id (var-get next-campaign-id))
        )
        (asserts! (not (var-get contract-paused)) err-contract-paused)
        (asserts! (> goal u0) err-invalid-amount)
        (asserts! (> deadline block-height) err-deadline-passed)
        (asserts! (< deadline (+ block-height u10000)) err-invalid-deadline)
        
        (map-set campaigns
            { campaign-id: campaign-id }
            {
                owner: tx-sender,
                goal: goal,
                deadline: deadline,
                raised: u0,
                claimed: false,
                status: (var-get campaign-status-active)
            }
        )
        
        (var-set next-campaign-id (+ campaign-id u1))
        (ok campaign-id)
    )
)

;; Contribute STX to a campaign
(define-public (contribute (campaign-id uint) (amount uint))
    (let
        (
            (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) err-campaign-not-found))
            (current-contribution (default-to { total-amount: u0 } 
                (map-get? contributions { campaign-id: campaign-id, contributor: tx-sender })))
        )
        (asserts! (not (var-get contract-paused)) err-contract-paused)
        (asserts! (<= block-height (get deadline campaign)) err-deadline-passed)
        (asserts! (> amount u0) err-invalid-amount)
        (asserts! (is-eq (get status campaign) (var-get campaign-status-active)) err-deadline-passed)
        (asserts! (<= amount (stx-get-balance tx-sender)) err-insufficient-balance)
        
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        
        (map-set campaigns
            { campaign-id: campaign-id }
            (merge campaign { raised: (+ (get raised campaign) amount) })
        )
        
        (map-set contributions
            { campaign-id: campaign-id, contributor: tx-sender }
            { total-amount: (+ (get total-amount current-contribution) amount) }
        )
        
        (ok true)
    )
)
