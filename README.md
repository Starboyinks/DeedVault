# DeedVault: Decentralized Property Registry

DeedVault is a decentralized property registry system built on the Stacks blockchain, enabling secure tokenization and management of real-world assets and digital items through smart contracts.

## Features

### Core Functionality
- **Deed Tokenization**: Create unique digital representations of real-world assets
- **Ownership Management**: Secure transfer and tracking of property ownership
- **Sale Mechanism**: Built-in marketplace functionality for deed trading
- **Burn and Reissue**: Mechanism for updating or correcting deed information
- **Transfer History**: On-chain proof of ownership with historical tracking

### Security Features
- Input validation for all user-provided data
- Owner-only access controls for sensitive operations
- Locked deed protection
- Comprehensive error handling
- Safe string length management

## Smart Contract Interface

### Public Functions

#### Deed Management
```clarity
(define-public (mint-deed (asset-type (string-ascii 64))
                         (description (string-ascii 256))
                         (uri (string-ascii 256)))
```
Creates a new deed token with specified properties.

```clarity
(define-public (burn-deed (deed-id uint))
```
Marks a deed as burned, preventing further transfers.

```clarity
(define-public (reissue-deed (burned-deed-id uint) 
                            (asset-type (string-ascii 64))
                            (description (string-ascii 256))
                            (uri (string-ascii 256)))
```
Creates a new deed linked to a previously burned deed.

#### Sale Functions
```clarity
(define-public (list-deed-for-sale (deed-id uint) (sale-price uint))
```
Lists a deed for sale at a specified price.

```clarity
(define-public (purchase-deed (deed-id uint))
```
Purchases a deed listed for sale, transferring STX payment.

### Read-Only Functions

```clarity
(define-read-only (get-deed-info (deed-id uint)))
(define-read-only (get-deed-owner (deed-id uint)))
(define-read-only (get-total-deeds))
(define-read-only (is-deed-burned (deed-id uint)))
(define-read-only (get-reissued-deed-id (burned-deed-id uint)))
(define-read-only (get-deed-sale-info (deed-id uint)))
(define-read-only (get-deed-history (deed-id uint)))
```

## Error Codes

| Code | Description |
|------|-------------|
| u100 | Owner-only operation |
| u101 | Not token owner |
| u102 | Token not found |
| u103 | Token already exists |
| u104 | Invalid token |
| u105 | Transfer failed |
| u106 | Insufficient funds |
| u107 | Not for sale |
| u108 | Already burned |
| u109 | Invalid asset type |
| u110 | Invalid description |
| u111 | Invalid URI |

## Data Structures

### Deed Object
```clarity
{
    owner: principal,
    asset-type: (string-ascii 64),
    description: (string-ascii 256),
    uri: (string-ascii 256),
    creation-time: uint,
    last-modified: uint,
    is-locked: bool,
    is-burned: bool,
    price: (optional uint),
    for-sale: bool,
    transfer-history: (list 10 principal)
}
```

## Development Setup

1. Install Clarinet for local development:
```bash
curl -L https://github.com/hirosystems/clarinet/releases/download/v1.5.4/clarinet-linux-x64.tar.gz | tar -xz
```

2. Initialize a new project:
```bash
clarinet new deedvault
cd deedvault
```

3. Deploy contract:
```bash
clarinet contract deploy
```

4. Run tests:
```bash
clarinet test
```

## Usage Examples

### Minting a New Deed
```clarity
(contract-call? .deedvault mint-deed "real-estate" "123 Main St, City" "ipfs://Qm...")
```

### Listing a Deed for Sale
```clarity
(contract-call? .deedvault list-deed-for-sale u1 u1000000)
```

### Purchasing a Deed
```clarity
(contract-call? .deedvault purchase-deed u1)
```

## Security Considerations

- All input strings are validated for length and content
- Owner verification is required for sensitive operations
- Burned deeds cannot be transferred or modified
- STX transfers are protected with proper error handling
- Transfer history is maintained for ownership verification

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request


## Support

For support and questions, please open an issue in the GitHub repository.