# ADNEXA — Legal & Trust Readiness Checklist (Thailand)

> This is an operational checklist, not a legal opinion. Do not launch customer-facing paid services until applicable items are completed and reviewed by Thai counsel.

## A. Business identity and legal scope
- [ ] Decide operator: individual or Thai juristic person; verify registration, tax, address and authorized signatory.
- [ ] Map every product feature, revenue flow, payment flow and contract party.
- [ ] Confirm whether the service triggers any registration, licensing, notification, tax, e-commerce, payment, advertising or sector-specific obligations.
- [ ] Document ADNEXA's role for each activity: service provider, data controller, data processor, or joint controller as facts require.
- [ ] Review platform developer terms, OAuth scopes, API policies, ad policies and data use restrictions for Meta, Google and TikTok before integration.

## B. Customer contracts and consumer fairness
- [ ] Publish Thai Terms of Service and Privacy Notice before signup/purchase.
- [ ] Use separate, unticked controls for mandatory notice acknowledgment and optional marketing consent.
- [ ] Present fees, tax, billing, ad spend, cancellation, refund, credit expiry and dispute rules before payment.
- [ ] Obtain clear affirmative acceptance for material terms; record exact document version and timestamp.
- [ ] Never use blanket clauses that say ADNEXA has zero liability, customer waives all claims, no refunds in all circumstances, or ADNEXA may change anything without notice.
- [ ] Have Thai counsel review Unfair Contract Terms Act, Consumer Protection Act, Direct Sales and Direct Marketing Act (if applicable), Electronic Transactions Act and Civil and Commercial Code.
- [ ] Provide a real complaint, appeal, cancellation and refund channel.

## C. PDPA program
- [ ] Create data inventory and Record of Processing Activities (RoPA).
- [ ] Map purpose, data category, lawful basis, recipients, retention and deletion for each processing activity.
- [ ] Identify processors/subprocessors and execute appropriate data processing agreements.
- [ ] Document cross-border transfers and applicable safeguards.
- [ ] Provide rights request intake and response workflow.
- [ ] Record consent/withdrawal separately by purpose and notice version; no pre-ticked consent.
- [ ] Set retention schedules, deletion jobs and legal-hold exceptions.
- [ ] Assess DPO appointment requirements and publish contact details where required.
- [ ] Implement breach triage and notification workflow; assess statutory notification deadlines and risk thresholds promptly.

## D. Security, backup and incident response
- [ ] Enforce MFA for administrators and least-privilege roles.
- [ ] Use secure secret management; no private keys/service-account keys in Git or app builds.
- [ ] Encrypt data in transit and at rest; protect OAuth tokens with managed key encryption.
- [ ] Enable audit logs for admin access, exports, consent changes and privileged actions.
- [ ] Configure automated backups and retention; alert on backup failure.
- [ ] Test restoration in an isolated environment and record actual RPO/RTO.
- [ ] Establish incident commander, escalation contacts, evidence preservation and customer communications.
- [ ] Run vulnerability/dependency scans and security tests before launch.

## E. Advertising and payments
- [ ] Keep ad spend in customer's own platform account, paid directly to the platform unless a reviewed alternative is deliberately adopted.
- [ ] Require user confirmation before campaign launch, budget changes and other high-impact actions.
- [ ] Show platform, account, campaign, budget, audience and authorization scope before execution.
- [ ] Keep immutable audit events for approvals, changes, API results and failures.
- [ ] Do not promise sales, leads or ROAS unless a precise written guarantee and remedy is approved.
- [ ] Clearly separate ADNEXA subscription/management fees from platform media spend.
- [ ] Use a licensed payment provider; do not store full card data or CVV.
- [ ] Reconcile payments, refunds, disputes and chargebacks with evidence.

## F. Go-live gate
- [ ] Thai lawyer has reviewed terms, privacy, consent, refunds, ad operation and business model.
- [ ] All legal entity/contact placeholders are completed.
- [ ] Backup and restore test passed.
- [ ] Consent logs and withdrawal flow tested.
- [ ] Rights request and breach response tabletop exercises completed.
- [ ] No unresolved critical/high security findings.
- [ ] Product claims, ads and pricing reviewed for accuracy.
- [ ] Management signs a dated go-live approval.
