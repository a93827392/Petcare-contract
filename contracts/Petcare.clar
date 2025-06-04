;; title: Petcare
;; version: 1.0.0
;; summary: Pet Medical Emergency Coverage - Savings and Claims Contract
;; description: A decentralized pet insurance system for emergency medical coverage

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INSUFFICIENT_FUNDS (err u101))
(define-constant ERR_PET_NOT_FOUND (err u102))
(define-constant ERR_CLAIM_NOT_FOUND (err u103))
(define-constant ERR_CLAIM_ALREADY_PROCESSED (err u104))
(define-constant ERR_INVALID_AMOUNT (err u105))
(define-constant ERR_CLAIM_EXPIRED (err u106))
(define-constant ERR_PET_ALREADY_REGISTERED (err u107))

(define-data-var next-pet-id uint u1)
(define-data-var next-claim-id uint u1)
(define-data-var total-pool-funds uint u0)
(define-data-var emergency-threshold uint u1000000)

(define-map pets
  { pet-id: uint }
  {
    owner: principal,
    name: (string-ascii 50),
    species: (string-ascii 20),
    age: uint,
    monthly-contribution: uint,
    total-contributed: uint,
    coverage-start: uint,
    active: bool
  }
)

(define-map pet-owners
  { owner: principal, pet-name: (string-ascii 50) }
  { pet-id: uint }
)

(define-map claims
  { claim-id: uint }
  {
    pet-id: uint,
    owner: principal,
    amount: uint,
    description: (string-ascii 200),
    veterinarian: (string-ascii 100),
    claim-date: uint,
    status: (string-ascii 20),
    approved-amount: uint
  }
)

(define-map user-balances
  { user: principal }
  { balance: uint }
)

(define-public (register-pet (name (string-ascii 50)) (species (string-ascii 20)) (age uint) (monthly-contribution uint))
  (let
    (
      (pet-id (var-get next-pet-id))
      (existing-pet (map-get? pet-owners { owner: tx-sender, pet-name: name }))
    )
    (asserts! (is-none existing-pet) ERR_PET_ALREADY_REGISTERED)
    (asserts! (> monthly-contribution u0) ERR_INVALID_AMOUNT)
    (map-set pets
      { pet-id: pet-id }
      {
        owner: tx-sender,
        name: name,
        species: species,
        age: age,
        monthly-contribution: monthly-contribution,
        total-contributed: u0,
        coverage-start: stacks-block-height,
        active: true
      }
    )
    (map-set pet-owners
      { owner: tx-sender, pet-name: name }
      { pet-id: pet-id }
    )
    (var-set next-pet-id (+ pet-id u1))
    (ok pet-id)
  )
)

(define-public (make-monthly-contribution (pet-id uint))
  (let
    (
      (pet-data (unwrap! (map-get? pets { pet-id: pet-id }) ERR_PET_NOT_FOUND))
      (contribution-amount (get monthly-contribution pet-data))
      (current-balance (default-to u0 (get balance (map-get? user-balances { user: tx-sender }))))
    )
    (asserts! (is-eq (get owner pet-data) tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (get active pet-data) ERR_PET_NOT_FOUND)
    (asserts! (>= current-balance contribution-amount) ERR_INSUFFICIENT_FUNDS)
    (map-set user-balances
      { user: tx-sender }
      { balance: (- current-balance contribution-amount) }
    )
    (map-set pets
      { pet-id: pet-id }
      (merge pet-data { total-contributed: (+ (get total-contributed pet-data) contribution-amount) })
    )
    (var-set total-pool-funds (+ (var-get total-pool-funds) contribution-amount))
    (ok true)
  )
)

(define-public (deposit-funds (amount uint))
  (let
    (
      (current-balance (default-to u0 (get balance (map-get? user-balances { user: tx-sender }))))
    )
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set user-balances
      { user: tx-sender }
      { balance: (+ current-balance amount) }
    )
    (ok true)
  )
)

(define-public (submit-claim (pet-id uint) (amount uint) (description (string-ascii 200)) (veterinarian (string-ascii 100)))
  (let
    (
      (pet-data (unwrap! (map-get? pets { pet-id: pet-id }) ERR_PET_NOT_FOUND))
      (claim-id (var-get next-claim-id))
    )
    (asserts! (is-eq (get owner pet-data) tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (get active pet-data) ERR_PET_NOT_FOUND)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (>= amount (var-get emergency-threshold)) ERR_INVALID_AMOUNT)
    (map-set claims
      { claim-id: claim-id }
      {
        pet-id: pet-id,
        owner: tx-sender,
        amount: amount,
        description: description,
        veterinarian: veterinarian,
        claim-date: stacks-block-height,
        status: "pending",
        approved-amount: u0
      }
    )
    (var-set next-claim-id (+ claim-id u1))
    (ok claim-id)
  )
)

(define-public (approve-claim (claim-id uint) (approved-amount uint))
  (let
    (
      (claim-data (unwrap! (map-get? claims { claim-id: claim-id }) ERR_CLAIM_NOT_FOUND))
      (pet-data (unwrap! (map-get? pets { pet-id: (get pet-id claim-data) }) ERR_PET_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status claim-data) "pending") ERR_CLAIM_ALREADY_PROCESSED)
    (asserts! (<= approved-amount (get amount claim-data)) ERR_INVALID_AMOUNT)
    (asserts! (<= approved-amount (var-get total-pool-funds)) ERR_INSUFFICIENT_FUNDS)
    (map-set claims
      { claim-id: claim-id }
      (merge claim-data { status: "approved", approved-amount: approved-amount })
    )
    (var-set total-pool-funds (- (var-get total-pool-funds) approved-amount))
    (try! (as-contract (stx-transfer? approved-amount tx-sender (get owner claim-data))))
    (ok true)
  )
)

(define-public (reject-claim (claim-id uint))
  (let
    (
      (claim-data (unwrap! (map-get? claims { claim-id: claim-id }) ERR_CLAIM_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status claim-data) "pending") ERR_CLAIM_ALREADY_PROCESSED)
    (map-set claims
      { claim-id: claim-id }
      (merge claim-data { status: "rejected" })
    )
    (ok true)
  )
)

(define-public (withdraw-funds (amount uint))
  (let
    (
      (current-balance (default-to u0 (get balance (map-get? user-balances { user: tx-sender }))))
    )
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (>= current-balance amount) ERR_INSUFFICIENT_FUNDS)
    (map-set user-balances
      { user: tx-sender }
      { balance: (- current-balance amount) }
    )
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    (ok true)
  )
)

(define-public (deactivate-pet (pet-id uint))
  (let
    (
      (pet-data (unwrap! (map-get? pets { pet-id: pet-id }) ERR_PET_NOT_FOUND))
    )
    (asserts! (is-eq (get owner pet-data) tx-sender) ERR_NOT_AUTHORIZED)
    (map-set pets
      { pet-id: pet-id }
      (merge pet-data { active: false })
    )
    (ok true)
  )
)

(define-public (update-emergency-threshold (new-threshold uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (var-set emergency-threshold new-threshold)
    (ok true)
  )
)

(define-read-only (get-pet-info (pet-id uint))
  (map-get? pets { pet-id: pet-id })
)

(define-read-only (get-pet-by-owner-and-name (owner principal) (pet-name (string-ascii 50)))
  (match (map-get? pet-owners { owner: owner, pet-name: pet-name })
    pet-ref (map-get? pets { pet-id: (get pet-id pet-ref) })
    none
  )
)

(define-read-only (get-claim-info (claim-id uint))
  (map-get? claims { claim-id: claim-id })
)

(define-read-only (get-user-balance (user principal))
  (default-to u0 (get balance (map-get? user-balances { user: user })))
)

(define-read-only (get-total-pool-funds)
  (var-get total-pool-funds)
)

(define-read-only (get-emergency-threshold)
  (var-get emergency-threshold)
)

(define-read-only (get-contract-stats)
  {
    total-pets: (- (var-get next-pet-id) u1),
    total-claims: (- (var-get next-claim-id) u1),
    total-pool-funds: (var-get total-pool-funds),
    emergency-threshold: (var-get emergency-threshold)
  }
)