# KBS-task
Task Bounty Smart Contract – Kharagpur Blockchain Society Sophomore Selections 202
# Task Bounty Smart Contract

## Kharagpur Blockchain Society – Sophomore Selections 2026

This project implements a blockchain-based **Task Bounty Smart Contract** using Solidity.

The contract allows a poster to create a paid bounty by locking ETH in the smart contract. Participants can submit their work before the submission deadline. The poster can select a winner and the locked reward is automatically transferred to the winner.

The contract also provides a timeout mechanism so that the reward cannot remain permanently locked if the poster becomes inactive.

---

## Problem Statement

In a normal bounty system, a poster may create a task and lock money as a reward. However, if the poster becomes inactive or does not select a winner, the submitted work may remain unrewarded and the locked funds may remain stuck.

The smart contract solves this problem by implementing:

- ETH locked at bounty creation
- Submission deadlines
- Decision deadlines
- Winner selection
- Automatic timeout fallback
- Refund when there are no submissions
- Reentrancy protection
- Prevention of duplicate settlement

---

## Solution

The smart contract follows this workflow:

1. The poster creates a bounty and deposits ETH.
2. Participants submit their work before the submission deadline.
3. The poster can select one of the submitters as the winner.
4. The winner receives the locked ETH immediately.
5. If the poster does not select a winner before the decision deadline:
   - If there are submissions, the reward is equally distributed among the submitters.
   - If there are no submissions, the poster can reclaim the locked ETH.

This ensures that the bounty funds always have a defined exit path.

---

## Main Features

### 1. Post Bounty

The poster creates the bounty by providing:

- Bounty title
- Bounty description
- Submission duration
- Decision duration
- ETH reward

The ETH reward is locked inside the smart contract at creation.

---

### 2. Submit Work

Any address other than the poster can submit work before the submission deadline.

Each address can submit only once.

The submitted work can be represented using a text description or a link.

---

### 3. Winner Selection

Only the bounty poster can select the winner.

The selected address must be one of the valid submitters.

After the winner is selected:

- The bounty is marked as paid.
- The winner receives the locked ETH.
- The bounty cannot be settled again.

---

### 4. Timeout Fallback

If the poster does not select a winner before the decision deadline, the contract provides a fallback mechanism.

#### Case 1: Submissions exist

The locked reward is divided equally among all valid submitters.

For example:

If the bounty reward is:

1 ETH

and there are:

2 submitters

then each submitter receives:

0.5 ETH

If integer division creates a small remainder, the remainder is returned to the poster.

#### Case 2: No submissions

If nobody submits work before the decision deadline, the poster can call `reclaim()`.

The complete locked reward is returned to the poster.

---

## Why the Timeout Fallback Prevents Stuck Funds

The contract has explicit withdrawal/settlement paths for every situation.

There are three possible outcomes:

1. **Winner selected**
   - ETH is transferred to the winner.

2. **Submissions exist but poster does not decide**
   - ETH is distributed equally among submitters after the decision deadline.

3. **No submissions**
   - ETH is returned to the poster after the decision deadline.

Therefore, the ETH deposited into the bounty contract does not depend indefinitely on the poster taking an action.

---

## Status System

The contract uses four statuses:

| Status | Meaning |
|---|---|
| Open | Participants can submit work |
| AwaitingDecision | Submission period has ended and poster can select a winner |
| Paid | Bounty has been settled |
| Expired | Decision deadline has passed but the bounty has not yet been settled |

The `getStatus()` function returns the current bounty status.

---

## Security Measures

The contract includes several security checks:

### Reentrancy Protection

A `nonReentrant` modifier is used for ETH payout functions to prevent reentrancy attacks.

### No Self-Selection

The poster cannot submit their own work.

### One Submission Per Address

The `hasSubmitted` mapping prevents the same address from submitting more than once.

### No Double Payment

Once the bounty is settled, `bounty.paid` becomes `true`.

The `notPaid` modifier prevents:

- Selecting another winner
- Running fallback distribution again
- Reclaiming the reward again

### Winner Must Be a Submitter

The selected winner must have submitted work.

### Deadline Protection

Submissions, winner selection, fallback distribution and refund are only allowed during their respective valid time periods.

### Every Wei Has an Exit Path

The reward can be transferred to:

- The selected winner
- The valid submitters through timeout fallback
- The poster when there are zero submissions

---

## Testing and Demonstration

The smart contract was compiled and tested using:

- Solidity `^0.8.20`
- Remix IDE
- Remix VM Osaka
- Test ETH

### Demo 1 – Normal Winner Selection

A bounty was created with ETH locked in the contract.

Multiple participants submitted their work.

The poster selected one valid submitter as the winner.

The winner received the bounty reward and the contract balance became zero.

**Result:** Bounty status became `Paid`.

---

### Demo 2 – Timeout With Submissions

A bounty was created and multiple participants submitted their work.

The poster did not select a winner before the decision deadline.

After the decision deadline passed, the timeout fallback was triggered.

The reward was equally distributed among the submitters.

**Result:** The bounty was settled through the timeout fallback.

---

### Demo 3 – Timeout With Zero Submissions

A bounty was created with ETH locked in the contract.

No participant submitted any work.

After the decision deadline passed, the poster called `reclaim()`.

The locked reward was returned to the poster.

**Result:** Bounty status became `Paid` and the contract balance became zero.

---

## Smart Contract Functions

### `constructor()`

Creates a new bounty and locks the ETH reward inside the contract.

### `submitWork()`

Allows eligible participants to submit their work before the submission deadline.

### `selectWinner()`

Allows only the poster to select a valid submitter as the winner.

### `fallbackDistribute()`

Distributes the reward equally among submitters after the decision deadline if the poster has not selected a winner.

### `reclaim()`

Allows the poster to reclaim the reward after the decision deadline when there are zero submissions.

### `getStatus()`

Returns the current status of the bounty.

### `getSubmissionsCount()`

Returns the number of submissions.

### `getAllSubmissions()`

Returns all submitted work details.

---

## Technology Used

- **Solidity**
- **Remix IDE**
- **Remix VM Osaka**
- **Ethereum Smart Contract**

---

## Project Structure

```text
task-bounty/
│
├── README.md
│
└── ShivankTaskBounty.sol
