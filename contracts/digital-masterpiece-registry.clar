;; Digital Masterpiece Registry 
;; This contract provides a comprehensive system for cataloging, securing, and managing digital masterpiece on the blockchain. It implements robust validation for artwork metadata and enforces permissions for viewing and transferring ownership of registered digital creations.

;; -----------------------------
;; Fundamental Constants
;; -----------------------------
;; Set contract administrator to the deploying address
(define-constant REGISTRY-ADMINISTRATOR tx-sender)


(define-constant ERROR-INVALID-VIEWER (err u306))                 ;; Target viewer account is invalid
(define-constant ERROR-ADMIN-RESTRICTED (err u307));; Operation limited to administrator only
;; System Response Codes
(define-constant ERROR-MASTERPIECE-NONEXISTENT (err u301))        ;; Masterpiece ID not found in registry
(define-constant ERROR-MASTERPIECE-ALREADY-EXISTS (err u302))     ;; Attempted to register duplicate masterpiece
(define-constant ERROR-INVALID-MASTERPIECE-DIMENSIONS (err u304)) ;; Dimensions value falls outside acceptable range
(define-constant ERROR-PERMISSION-DENIED (err u305))              ;; Action attempted by unauthorized party
(define-constant ERROR-NO-VIEWING-RIGHTS (err u308))              ;; User lacks permission to view masterpiece
(define-constant ERROR-INVALID-MASTERPIECE-NAME (err u303))       ;; Provided name doesn't meet format requirements


;; -----------------------------
;; Registry Data Structure
;; -----------------------------
;; Track the total number of registered masterpieces
(define-data-var masterpiece-count uint u0)

;; Primary registry containing all masterpiece details
(define-map masterpiece-registry
  { masterpiece-id: uint }  ;; Unique identifier for each masterpiece
  {
    name: (string-ascii 64),             ;; Official name of the masterpiece
    artist: principal,                   ;; Blockchain identity of the artist
    dimensions: uint,                    ;; Digital dimensions identifier
    registration-block: uint,            ;; Block height at registration time
    artist-notes: (string-ascii 128),    ;; Additional context provided by artist
    categories: (list 10 (string-ascii 32)) ;; Classification categories for searching
  }
)

;; Viewing permissions registry
(define-map viewing-permissions
  { masterpiece-id: uint, viewer: principal }  ;; Masterpiece ID and viewer pairing
  { can-view: bool }                         ;; Permission status flag
)

;; -----------------------------
;; Utility Functions
;; -----------------------------
;; Verify existence of masterpiece in the registry
(define-private (masterpiece-registered? (masterpiece-id uint))
  (is-some (map-get? masterpiece-registry { masterpiece-id: masterpiece-id }))
)

;; Confirm if a user is the rightful artist of a masterpiece
(define-private (is-masterpiece-artist? (masterpiece-id uint) (artist principal))
  (match (map-get? masterpiece-registry { masterpiece-id: masterpiece-id })
    masterpiece-data (is-eq (get artist masterpiece-data) artist)
    false
  )
)

;; Validate string length is within acceptable range
(define-private (validate-text-length (text (string-ascii 64)) (min-length uint) (max-length uint))
  (and 
    (>= (len text) min-length)
    (<= (len text) max-length)
  )
)

;; Increment the masterpiece counter and return previous value
(define-private (increment-masterpiece-counter)
  (let ((current-count (var-get masterpiece-count)))
    (var-set masterpiece-count (+ current-count u1))
    (ok current-count)
  )
)

;; Retrieve the dimensions of a registered masterpiece
(define-private (extract-masterpiece-dimensions (masterpiece-id uint))
  (default-to u0 
    (get dimensions 
      (map-get? masterpiece-registry { masterpiece-id: masterpiece-id })
    )
  )
)

;; Ensure category tag meets formatting requirements
(define-private (is-category-valid? (category (string-ascii 32)))
  (and 
    (> (len category) u0)     ;; Category must contain at least one character
    (< (len category) u33)    ;; Category must not exceed 32 characters
  )
)

;; Validate the entire collection of categories
(define-private (are-categories-valid? (categories (list 10 (string-ascii 32))))
  (and
    (> (len categories) u0)                 ;; At least one category required
    (<= (len categories) u10)               ;; Maximum of 10 categories allowed
    (is-eq (len (filter is-category-valid? categories)) (len categories))  ;; All categories must be valid
  )
)

;; -----------------------------
;; Primary Registry Operations
;; -----------------------------
;; Register a new digital masterpiece
(define-public (register-masterpiece (name (string-ascii 64)) (dimensions uint) (artist-notes (string-ascii 128)) (categories (list 10 (string-ascii 32))))
  (let
    (
      (new-masterpiece-id (+ (var-get masterpiece-count) u1))  ;; Generate sequential ID
    )
    ;; Validate submission parameters
    (asserts! (and (> (len name) u0) (< (len name) u65)) ERROR-INVALID-MASTERPIECE-NAME)  
    (asserts! (and (> dimensions u0) (< dimensions u1000000000)) ERROR-INVALID-MASTERPIECE-DIMENSIONS)
    (asserts! (and (> (len artist-notes) u0) (< (len artist-notes) u129)) ERROR-INVALID-MASTERPIECE-NAME)
    (asserts! (are-categories-valid? categories) ERROR-INVALID-MASTERPIECE-NAME)

    ;; Store masterpiece data in registry
    (map-insert masterpiece-registry
      { masterpiece-id: new-masterpiece-id }
      {
        name: name,
        artist: tx-sender,
        dimensions: dimensions,
        registration-block: block-height,
        artist-notes: artist-notes,
        categories: categories
      }
    )

    ;; Grant viewing rights to artist automatically
    (map-insert viewing-permissions
      { masterpiece-id: new-masterpiece-id, viewer: tx-sender }
      { can-view: true }
    )

    ;; Update registry statistics
    (var-set masterpiece-count new-masterpiece-id)
    (ok new-masterpiece-id)  ;; Return the ID of the newly registered masterpiece
  )
)

;; Retrieve artist notes for a masterpiece
(define-public (retrieve-masterpiece-notes (masterpiece-id uint))
  (let
    (
      (masterpiece-data (unwrap! (map-get? masterpiece-registry { masterpiece-id: masterpiece-id }) ERROR-MASTERPIECE-NONEXISTENT))
    )
    (ok (get artist-notes masterpiece-data))
  )
)

;; Verify viewing permissions for a specific user
(define-public (verify-viewing-access (masterpiece-id uint) (viewer principal))
  (let
    (
      (permission-data (map-get? viewing-permissions { masterpiece-id: masterpiece-id, viewer: viewer }))
    )
    (ok (is-some permission-data))
  )
)

;; Count categories associated with a masterpiece
(define-public (count-masterpiece-categories (masterpiece-id uint))
  (let
    (
      (masterpiece-data (unwrap! (map-get? masterpiece-registry { masterpiece-id: masterpiece-id }) ERROR-MASTERPIECE-NONEXISTENT))
    )
    (ok (len (get categories masterpiece-data)))
  )
)

;; Validate masterpiece name format
(define-public (validate-masterpiece-name (name (string-ascii 64)))
  (ok (and (> (len name) u0) (<= (len name) u64)))
)

;; Transfer masterpiece ownership to another artist
(define-public (transfer-masterpiece-rights (masterpiece-id uint) (new-artist principal))
  (let
    (
      (masterpiece-data (unwrap! (map-get? masterpiece-registry { masterpiece-id: masterpiece-id }) ERROR-MASTERPIECE-NONEXISTENT))
    )
    (asserts! (masterpiece-registered? masterpiece-id) ERROR-MASTERPIECE-NONEXISTENT)
    (asserts! (is-eq (get artist masterpiece-data) tx-sender) ERROR-PERMISSION-DENIED)

    ;; Update registry with new artist information
    (map-set masterpiece-registry
      { masterpiece-id: masterpiece-id }
      (merge masterpiece-data { artist: new-artist })
    )
    (ok true)
  )
)

;; Update metadata for an existing masterpiece
(define-public (update-masterpiece-details (masterpiece-id uint) (updated-name (string-ascii 64)) (updated-dimensions uint) (updated-notes (string-ascii 128)) (updated-categories (list 10 (string-ascii 32))))
  (let
    (
      (masterpiece-data (unwrap! (map-get? masterpiece-registry { masterpiece-id: masterpiece-id }) ERROR-MASTERPIECE-NONEXISTENT))
    )
    ;; Perform validation checks
    (asserts! (masterpiece-registered? masterpiece-id) ERROR-MASTERPIECE-NONEXISTENT)
    (asserts! (is-eq (get artist masterpiece-data) tx-sender) ERROR-PERMISSION-DENIED)
    (asserts! (and (> (len updated-name) u0) (< (len updated-name) u65)) ERROR-INVALID-MASTERPIECE-NAME)
    (asserts! (and (> updated-dimensions u0) (< updated-dimensions u1000000000)) ERROR-INVALID-MASTERPIECE-DIMENSIONS)
    (asserts! (and (> (len updated-notes) u0) (< (len updated-notes) u129)) ERROR-INVALID-MASTERPIECE-NAME)
    (asserts! (are-categories-valid? updated-categories) ERROR-INVALID-MASTERPIECE-NAME)

    ;; Apply updates to registry
    (map-set masterpiece-registry
      { masterpiece-id: masterpiece-id }
      (merge masterpiece-data { 
        name: updated-name, 
        dimensions: updated-dimensions, 
        artist-notes: updated-notes, 
        categories: updated-categories 
      })
    )
    (ok true)
  )
)

;; Remove masterpiece from registry
(define-public (remove-masterpiece (masterpiece-id uint))
  (let
    (
      (masterpiece-data (unwrap! (map-get? masterpiece-registry { masterpiece-id: masterpiece-id }) ERROR-MASTERPIECE-NONEXISTENT))
    )
    (asserts! (masterpiece-registered? masterpiece-id) ERROR-MASTERPIECE-NONEXISTENT)
    (asserts! (is-eq (get artist masterpiece-data) tx-sender) ERROR-PERMISSION-DENIED)

    ;; Delete masterpiece from registry
    (map-delete masterpiece-registry { masterpiece-id: masterpiece-id })
    (ok true)
  )
)

