
#  sBTC-CrowdForge Smart Contract

**Decentralized Crowdfunding Platform with Bitcoin-backed Security**

---

## Overview

**sBTC-CrowdForge** is a Clarity smart contract built for the Stacks blockchain that enables decentralized crowdfunding. Campaign creators can raise funds with transparent, blockchain-based tracking, while contributors are assured their funds are either used toward successful goals or safely refundable.

---

## Features

✅ Decentralized campaign creation and funding
✅ STX contributions secured by Clarity logic
✅ Refund system for unsuccessful campaigns
✅ Time-bound campaign logic (deadlines and extensions)
✅ Ownership-restricted actions for fund claims and campaign cancellation
✅ Historical contribution tracking per user

---

## Table of Contents

* [Installation](#installation)
* [How It Works](#how-it-works)
* [Smart Contract Functions](#smart-contract-functions)
* [Error Codes](#error-codes)
* [Security](#security)
* [Contributing](#contributing)
* [License](#license)

---

## Installation

Deploy this smart contract using the [Stacks CLI](https://docs.stacks.co/docs/cli/overview/) or a platform like [Clarinet](https://docs.hiro.so/clarinet/get-started/installation).

```bash
# Deploy via Clarinet
clarinet integrate
clarinet deploy
```

---

## How It Works

1. **Campaign Creation**: A user can create a crowdfunding campaign by specifying a goal and a deadline (block height).
2. **Contributions**: Contributors can send STX to active campaigns until the deadline.
3. **Claiming Funds**: If the funding goal is met, the campaign owner can claim the raised funds.
4. **Refunds**: If a campaign fails to meet its goal before the deadline, contributors can refund their STX.
5. **Campaign Lifecycle Management**: Campaigns can be updated, canceled (if no funds), and queried for status and history.

---

## Smart Contract Functions

### 🏗️ Campaign Lifecycle

* `create-campaign (goal uint) (deadline uint)`

  * Creates a new campaign.
* `cancel-campaign (campaign-id uint)`

  * Cancels a campaign (only if no contributions and by owner).
* `update-deadline (campaign-id uint) (new-deadline uint)`

  * Extend a campaign's deadline (by owner only).

### 💸 Contributions

* `contribute (campaign-id uint) (amount uint)`

  * Allows users to contribute STX to a campaign.

### 🧾 Funds & Claims

* `claim-funds (campaign-id uint)`

  * Campaign owner claims raised funds after reaching the goal.
* `refund (campaign-id uint)`

  * Contributors get a refund if the campaign fails.

### 📊 Data Queries

* `get-campaign-status (campaign-id uint)`

  * Returns current stats: goal, total raised, remaining blocks, progress %, etc.
* `get-contribution-history (campaign-id uint) (contributor principal)`

  * View contribution details for a user in a specific campaign.

---

## Error Codes

| Code   | Error Message           | Explanation                                      |
| ------ | ----------------------- | ------------------------------------------------ |
| `u100` | Not Authorized          | Only campaign owner can perform certain actions. |
| `u101` | Campaign Already Exists | Prevents ID collisions during creation.          |
| `u102` | Invalid Amount          | Amount must be greater than 0.                   |
| `u103` | Deadline Passed         | Can't contribute or update after campaign ends.  |
| `u104` | Goal Not Met            | Prevents fund claim before goal is reached.      |
| `u105` | Already Claimed         | Funds already claimed.                           |
| `u106` | Invalid Campaign        | Campaign ID not found.                           |
| `u107` | Invalid Deadline        | New deadline must be in future.                  |
| `u108` | No Contribution         | No contribution found for refund/history.        |
| `u109` | Campaign Active         | Can't cancel an active (funded) campaign.        |

---

## Security

* **Immutable Funds Handling**: All STX transfers are permissionless and only triggered under proper conditions.
* **Refund Assurance**: Contributions are refundable if the campaign fails.
* **Owner Permissions**: Only owners can update, cancel, or claim from their campaigns.

---

## Contributing

Pull requests and improvements are welcome! Please open an issue first for major changes.

---

## License

MIT License. You are free to use, modify, and distribute under the terms of the MIT license.
