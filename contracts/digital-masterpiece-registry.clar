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
