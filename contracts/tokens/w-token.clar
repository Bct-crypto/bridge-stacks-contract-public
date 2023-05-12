(impl-trait .bridge-token-trait.bridge-token-trait)

(define-constant ERR-NOT-AUTHORIZED (err u10000))
(define-constant ERR-WRONG-PRINCIPAL (err u10001))
(define-constant ERR-WRONG-AMOUNT (err u10002))
(define-constant PRECISION u8)
(define-map approved-contracts principal bool)

(define-data-var token-uri (string-utf8 256) u"")
(define-data-var name (string-ascii 32) "Wrapped Token")
(define-data-var symbol (string-ascii 32) "wTOKEN")
(define-data-var contract-owner principal tx-sender)

(define-read-only 
	(get-contract-owner)
  	(ok (var-get contract-owner))
)

(define-public 
	(set-contract-owner (owner principal))
	(begin
		(asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
		(asserts! (is-standard owner) ERR-NOT-AUTHORIZED)
		(ok (var-set contract-owner owner))
	)
)

(define-fungible-token wrapped-token)

(define-read-only 
	(get-total-supply)
  	(ok (ft-get-supply wrapped-token))
)

(define-read-only 
	(get-name)
  	(ok (var-get name))
)

(define-read-only 
	(get-symbol)
  	(ok (var-get symbol))
)

(define-read-only 
	(get-decimals)
   	(ok PRECISION)
)

(define-read-only 
	(get-balance 
		(account principal)
	)
  	(ok (ft-get-balance wrapped-token account))
)

(define-public 
	(set-token-uri 
		(value (string-utf8 256))
	)
	(begin
		(asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
		(asserts! (is-eq (> (len value) u0) true) ERR-NOT-AUTHORIZED)
		(ok (var-set token-uri value))
	)
)

(define-public 
	(set-token-name 
		(value (string-ascii 32))
	)
	(begin
		(asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
		(asserts! (is-eq (> (len value) u0) true) ERR-NOT-AUTHORIZED)
		(ok (var-set name value))
	)
)

(define-public 
	(set-token-symbol 
		(value (string-ascii 32))
	)
	(begin
		(asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
		(asserts! (is-eq (> (len value) u0) true) ERR-NOT-AUTHORIZED)
		(ok (var-set symbol value))
	)
)

(define-read-only 
	(get-token-uri)
  	(ok (some (var-get token-uri)))
)

(define-public 
	(transfer 
		(amount uint) 
		(sender principal) 
		(recipient principal) 
		(memo (optional (buff 34)))
	)
	(begin
		(asserts! (is-standard sender) ERR-WRONG-PRINCIPAL)
		(asserts! (is-standard recipient) ERR-WRONG-PRINCIPAL)
		(asserts! (is-eq (> amount u0) true) ERR-WRONG-AMOUNT)
		(asserts! (or (is-eq sender tx-sender) 
						(is-eq contract-caller (var-get contract-owner))
				) ERR-NOT-AUTHORIZED)
		(if (is-eq sender (var-get contract-owner))
			(mint! recipient amount memo)
			(if (is-eq recipient (var-get contract-owner))
				(burn! sender amount memo)
				(transfer! amount sender recipient memo)
			)
		)
	)
)

;; Mint tokens
(define-private 
	(mint! 
		(recipient principal)
		(amount uint)
		(memo (optional (buff 34)))
	)
	(begin
		(asserts! (is-eq contract-caller (var-get contract-owner)) ERR-NOT-AUTHORIZED)
		(print { action: "mint-tokens", mint-amount: amount, mint-to: recipient })
		(match 
			(ft-mint? wrapped-token amount recipient)
			response (begin
				(print memo)
				(ok response)
			)
			error (err error)
		)
	)
)

;; Burn tokens
(define-private 
	(burn! 
		(sender principal)
		(amount uint)
		(memo (optional (buff 34)))
	)
	(begin
		(asserts! (is-eq contract-caller (var-get contract-owner)) ERR-NOT-AUTHORIZED)
		(print { action: "burn-tokens", burn-amount: amount, burn-from: sender })
		(match 
			(ft-burn? wrapped-token amount sender)
			response (begin
				(print memo)
				(ok response)
			)
			error (err error)
		)
	)
)

;; Burn tokens
(define-private 
	(transfer! 
		(amount uint)
		(sender principal)
		(recipient principal)
		(memo (optional (buff 34)))
	)
	(begin 
		(asserts! (is-eq sender tx-sender) ERR-NOT-AUTHORIZED)
		(print { action: "transfer-tokens", amount: amount, sender: sender, recipient: recipient })
		(match 
			(ft-transfer? wrapped-token amount sender recipient)
			response (begin
				(print memo)
				(ok response)
			)
			error (err error)
		)
	)
)

;; (mint! tx-sender u100000000000000 none)
;; (mint! 'ST1B5RJP7JKCSBZ8D1YN6XT6SSZYDSM6RXXWQHNA3 u100000000000000 none)
;; (mint! 'ST1365SNAKBPCB9AW7CQXWVCBKEE7RS2DG9V591VG u10000000000000 none)
;; (mint! 'ST1101EZXXBF6090JWBZRPH4N0KSZQ0E1S793HSPQ.bridge u100000000000000000 none)