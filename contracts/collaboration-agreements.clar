;; Collaboration Agreement Contract
;; Handles multi-artist project terms

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-AGREEMENT-NOT-FOUND (err u501))
(define-constant ERR-INVALID-INPUT (err u502))
(define-constant ERR-ALREADY-SIGNED (err u503))
(define-constant ERR-NOT-COLLABORATOR (err u504))
(define-constant ERR-AGREEMENT-FINALIZED (err u505))

;; Data Variables
(define-data-var next-agreement-id uint u1)

;; Data Maps
(define-map collaboration-agreements
  { agreement-id: uint }
  {
    project-title: (string-ascii 100),
    initiator: principal,
    creation-date: uint,
    total-collaborators: uint,
    signatures-required: uint,
    current-signatures: uint,
    is-finalized: bool,
    revenue-split-defined: bool
  }
)

(define-map collaborator-details
  { agreement-id: uint, collaborator: principal }
  {
    role: (string-ascii 50),
    contribution-percentage: uint,
    revenue-percentage: uint,
    has-signed: bool,
    signature-date: (optional uint)
  }
)

(define-map agreement-terms
  { agreement-id: uint }
  {
    project-duration: (optional uint),
    exclusive-rights: bool,
    territory: (string-ascii 100),
    usage-rights: (string-ascii 200),
    termination-clause: (string-ascii 300)
  }
)

(define-map collaboration-compositions
  { agreement-id: uint, composition-id: uint }
  { registered: bool, registration-date: uint }
)

(define-map collaborator-agreements
  { collaborator: principal, agreement-id: uint }
  { active: bool }
)

;; Public Functions

;; Create collaboration agreement
(define-public (create-collaboration-agreement
  (project-title (string-ascii 100))
  (collaborators (list 10 principal))
  (roles (list 10 (string-ascii 50)))
  (contribution-percentages (list 10 uint))
  (revenue-percentages (list 10 uint)))
  (let
    (
      (agreement-id (var-get next-agreement-id))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (total-collaborators (len collaborators))
    )
    (asserts! (> (len project-title) u0) ERR-INVALID-INPUT)
    (asserts! (> total-collaborators u0) ERR-INVALID-INPUT)
    (asserts! (is-eq (len collaborators) (len roles)) ERR-INVALID-INPUT)
    (asserts! (is-eq (len collaborators) (len contribution-percentages)) ERR-INVALID-INPUT)
    (asserts! (is-eq (len collaborators) (len revenue-percentages)) ERR-INVALID-INPUT)

    ;; Validate revenue percentages sum to 100
    (asserts! (is-eq (fold + revenue-percentages u0) u100) ERR-INVALID-INPUT)

    ;; Create main agreement
    (map-set collaboration-agreements
      { agreement-id: agreement-id }
      {
        project-title: project-title,
        initiator: tx-sender,
        creation-date: current-time,
        total-collaborators: total-collaborators,
        signatures-required: total-collaborators,
        current-signatures: u1, ;; Initiator automatically signs
        is-finalized: false,
        revenue-split-defined: true
      }
    )

    ;; Add collaborator details
    (try! (add-collaborators-to-agreement agreement-id collaborators roles contribution-percentages revenue-percentages))

    ;; Mark initiator as signed
    (map-set collaborator-details
      { agreement-id: agreement-id, collaborator: tx-sender }
      {
        role: "initiator",
        contribution-percentage: u0,
        revenue-percentage: u0,
        has-signed: true,
        signature-date: (some current-time)
      }
    )

    ;; Increment agreement ID
    (var-set next-agreement-id (+ agreement-id u1))

    (ok agreement-id)
  )
)

;; Sign collaboration agreement
(define-public (sign-agreement (agreement-id uint))
  (let
    (
      (agreement (unwrap! (map-get? collaboration-agreements { agreement-id: agreement-id }) ERR-AGREEMENT-NOT-FOUND))
      (collaborator-info (unwrap! (map-get? collaborator-details { agreement-id: agreement-id, collaborator: tx-sender }) ERR-NOT-COLLABORATOR))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (not (get is-finalized agreement)) ERR-AGREEMENT-FINALIZED)
    (asserts! (not (get has-signed collaborator-info)) ERR-ALREADY-SIGNED)

    ;; Update collaborator signature
    (map-set collaborator-details
      { agreement-id: agreement-id, collaborator: tx-sender }
      (merge collaborator-info {
        has-signed: true,
        signature-date: (some current-time)
      })
    )

    ;; Update agreement signature count
    (let
      (
        (new-signature-count (+ (get current-signatures agreement) u1))
      )
      (map-set collaboration-agreements
        { agreement-id: agreement-id }
        (merge agreement {
          current-signatures: new-signature-count,
          is-finalized: (is-eq new-signature-count (get signatures-required agreement))
        })
      )
    )

    ;; Track collaborator agreement
    (map-set collaborator-agreements
      { collaborator: tx-sender, agreement-id: agreement-id }
      { active: true }
    )

    (ok true)
  )
)

;; Add composition to collaboration
(define-public (add-composition-to-collaboration (agreement-id uint) (composition-id uint))
  (let
    (
      (agreement (unwrap! (map-get? collaboration-agreements { agreement-id: agreement-id }) ERR-AGREEMENT-NOT-FOUND))
      (collaborator-info (unwrap! (map-get? collaborator-details { agreement-id: agreement-id, collaborator: tx-sender }) ERR-NOT-COLLABORATOR))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (get is-finalized agreement) ERR-INVALID-INPUT)
    (asserts! (get has-signed collaborator-info) ERR-NOT-AUTHORIZED)

    (map-set collaboration-compositions
      { agreement-id: agreement-id, composition-id: composition-id }
      { registered: true, registration-date: current-time }
    )

    (ok true)
  )
)

;; Set agreement terms
(define-public (set-agreement-terms
  (agreement-id uint)
  (project-duration (optional uint))
  (exclusive-rights bool)
  (territory (string-ascii 100))
  (usage-rights (string-ascii 200))
  (termination-clause (string-ascii 300)))
  (let
    (
      (agreement (unwrap! (map-get? collaboration-agreements { agreement-id: agreement-id }) ERR-AGREEMENT-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get initiator agreement)) ERR-NOT-AUTHORIZED)
    (asserts! (not (get is-finalized agreement)) ERR-AGREEMENT-FINALIZED)

    (map-set agreement-terms
      { agreement-id: agreement-id }
      {
        project-duration: project-duration,
        exclusive-rights: exclusive-rights,
        territory: territory,
        usage-rights: usage-rights,
        termination-clause: termination-clause
      }
    )

    (ok true)
  )
)

;; Terminate collaboration agreement
(define-public (terminate-agreement (agreement-id uint))
  (let
    (
      (agreement (unwrap! (map-get? collaboration-agreements { agreement-id: agreement-id }) ERR-AGREEMENT-NOT-FOUND))
      (collaborator-info (unwrap! (map-get? collaborator-details { agreement-id: agreement-id, collaborator: tx-sender }) ERR-NOT-COLLABORATOR))
    )
    (asserts! (or (is-eq tx-sender (get initiator agreement)) (is-eq tx-sender CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)

    ;; Mark agreement as inactive for the collaborator
    (map-set collaborator-agreements
      { collaborator: tx-sender, agreement-id: agreement-id }
      { active: false }
    )

    (ok true)
  )
)

;; Private Functions

;; Add multiple collaborators to agreement
(define-private (add-collaborators-to-agreement
  (agreement-id uint)
  (collaborators (list 10 principal))
  (roles (list 10 (string-ascii 50)))
  (contribution-percentages (list 10 uint))
  (revenue-percentages (list 10 uint)))
  (let
    (
      (collaborator-data (zip collaborators roles contribution-percentages revenue-percentages))
    )
    (fold add-single-collaborator collaborator-data (ok agreement-id))
  )
)

;; Add single collaborator
(define-private (add-single-collaborator
  (collaborator-info { collaborator: principal, role: (string-ascii 50), contribution-pct: uint, revenue-pct: uint })
  (result (response uint uint)))
  (match result
    success-id
      (begin
        (map-set collaborator-details
          { agreement-id: success-id, collaborator: (get collaborator collaborator-info) }
          {
            role: (get role collaborator-info),
            contribution-percentage: (get contribution-pct collaborator-info),
            revenue-percentage: (get revenue-pct collaborator-info),
            has-signed: false,
            signature-date: none
          }
        )
        (ok success-id)
      )
    error-code (err error-code)
  )
)

;; Helper function to zip lists
(define-private (zip
  (list1 (list 10 principal))
  (list2 (list 10 (string-ascii 50)))
  (list3 (list 10 uint))
  (list4 (list 10 uint)))
  (map create-collaborator-tuple list1 list2 list3 list4)
)

;; Create collaborator tuple
(define-private (create-collaborator-tuple
  (collaborator principal)
  (role (string-ascii 50))
  (contribution-pct uint)
  (revenue-pct uint))
  { collaborator: collaborator, role: role, contribution-pct: contribution-pct, revenue-pct: revenue-pct }
)

;; Read-only Functions

;; Get collaboration agreement
(define-read-only (get-collaboration-agreement (agreement-id uint))
  (map-get? collaboration-agreements { agreement-id: agreement-id })
)

;; Get collaborator details
(define-read-only (get-collaborator-details (agreement-id uint) (collaborator principal))
  (map-get? collaborator-details { agreement-id: agreement-id, collaborator: collaborator })
)

;; Get agreement terms
(define-read-only (get-agreement-terms (agreement-id uint))
  (map-get? agreement-terms { agreement-id: agreement-id })
)

;; Get collaboration composition
(define-read-only (get-collaboration-composition (agreement-id uint) (composition-id uint))
  (map-get? collaboration-compositions { agreement-id: agreement-id, composition-id: composition-id })
)

;; Check if collaborator has active agreement
(define-read-only (is-collaborator-active (collaborator principal) (agreement-id uint))
  (default-to false (get active (map-get? collaborator-agreements { collaborator: collaborator, agreement-id: agreement-id })))
)

;; Check if agreement is finalized
(define-read-only (is-agreement-finalized (agreement-id uint))
  (match (map-get? collaboration-agreements { agreement-id: agreement-id })
    agreement (get is-finalized agreement)
    false
  )
)

;; Get next agreement ID
(define-read-only (get-next-agreement-id)
  (var-get next-agreement-id)
)
