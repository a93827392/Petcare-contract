# Petcare

# 🐾 Petcare - Pet Medical Emergency Coverage

A decentralized pet insurance system built on Stacks blockchain that enables pet owners to save for emergency medical expenses and submit claims for coverage.

## 🌟 Features

- 🐕 **Pet Registration**: Register your pets with monthly contribution plans
- 💰 **Savings Pool**: Make monthly contributions to build emergency coverage
- 🏥 **Emergency Claims**: Submit claims for medical emergencies above threshold
- ⚡ **Instant Approval**: Contract owner can approve/reject claims quickly
- 📊 **Transparent Tracking**: View all pet info, claims, and pool statistics

## 🚀 Getting Started

### Prerequisites

- Clarinet CLI installed
- Stacks wallet for testing

### Installation

```bash
git clone <your-repo>
cd petcare-contract
clarinet console
```

## 📖 Usage Guide

### 1. Register Your Pet 🐱

```clarity
(contract-call? .Petcare register-pet "Fluffy" "Cat" u3 u50000)
```

### 2. Deposit Funds 💳

```clarity
(contract-call? .Petcare deposit-funds u500000)
```

### 3. Make Monthly Contributions 📅

```clarity
(contract-call? .Petcare make-monthly-contribution u1)
```

### 4. Submit Emergency Claim 🚨

```clarity
(contract-call? .Petcare submit-claim u1 u2000000 "Emergency surgery for broken leg" "Dr. Smith Veterinary Clinic")
```

### 5. Check Pet Information 📋

```clarity
(contract-call? .Petcare get-pet-info u1)
```

## 🔧 Contract Functions

### Public Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `register-pet` | Register a new pet | name, species, age, monthly-contribution |
| `deposit-funds` | Add STX to your balance | amount |
| `make-monthly-contribution` | Pay monthly premium | pet-id |
| `submit-claim` | Submit emergency claim | pet-id, amount, description, veterinarian |
| `withdraw-funds` | Withdraw unused balance | amount |

### Read-Only Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `get-pet-info` | Get pet details | Pet information |
| `get-claim-info` | Get claim details | Claim information |
| `get-user-balance` | Check user balance | Balance amount |
| `get-contract-stats` | View contract statistics | Stats object |

## 💡 How It Works

1. **Registration Phase**: Pet owners register their pets with monthly contribution amounts
2. **Savings Phase**: Owners regularly contribute to build up emergency coverage
3. **Emergency Phase**: When emergencies occur, owners submit claims above the threshold
4. **Approval Phase**: Contract administrator reviews and approves legitimate claims
5. **Payout Phase**: Approved funds are automatically transferred to pet owners

## 🎯 Key Features

- **Emergency Threshold**: Only claims above 1,000,000 microSTX qualify
- **Contribution Tracking**: All contributions are tracked per pet
- **Pool Management**: Shared pool funds emergency payouts
- **Owner Controls**: Pet owners can deactivate coverage anytime

## 🔒 Security Features

- Owner-only claim approval system
- Insufficient funds protection
- Duplicate registration prevention
- Authorization checks on all operations

## 📊 Contract Statistics

View real-time statistics including:
- Total registered pets
- Total submitted claims  
- Available pool funds
- Current emergency threshold

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License.

