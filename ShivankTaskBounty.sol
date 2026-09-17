// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ShivankTaskBounty {
    enum Status {
        Open,
        AwaitingDecision,
        Paid,
        Expired
    }

    struct Submission {
        address submitter;
        string workDetails; // link or description of submitted work
    }

    struct Bounty {
        address payable poster;
        string title;
        string description;
        uint256 reward;
        uint256 submissionDeadline;
        uint256 decisionDeadline;
        bool paid;
        address winner;
    }

    Bounty public bounty;
    Submission[] public submissions;
    mapping(address => bool) public hasSubmitted;

    bool private locked;

    event BountyCreated(address indexed poster, uint256 reward, uint256 submissionDeadline, uint256 decisionDeadline);
    event WorkSubmitted(address indexed submitter, string workDetails);
    event WinnerSelected(address indexed winner, uint256 reward);
    event FallbackDistributed(uint256 totalAmount, uint256 perSubmitterShare);
    event RefundIssued(address indexed poster, uint256 amount);

    modifier onlyPoster() {
        require(msg.sender == bounty.poster, "Caller is not bounty poster");
        _;
    }

    modifier notPaid() {
        require(!bounty.paid, "Bounty already settled");
        _;
    }

    modifier nonReentrant() {
        require(!locked, "Reentrancy guard triggered");
        locked = true;
        _;
        locked = false;
    }

    constructor(
        string memory _title,
        string memory _description,
        uint256 _submissionDuration,
        uint256 _decisionDuration
    ) payable {
        require(msg.value > 0, "Reward must be greater than 0");
        require(_submissionDuration > 0, "Submission duration must be > 0");
        require(_decisionDuration > 0, "Decision duration must be > 0");

        bounty.poster = payable(msg.sender);
        bounty.title = _title;
        bounty.description = _description;
        bounty.reward = msg.value;
        bounty.submissionDeadline = block.timestamp + _submissionDuration;
        bounty.decisionDeadline = block.timestamp + _submissionDuration + _decisionDuration;
        bounty.paid = false;

        emit BountyCreated(msg.sender, msg.value, bounty.submissionDeadline, bounty.decisionDeadline);
    }

    // Submit work before the submission deadline
    function submitWork(string calldata _workDetails) external {
        require(block.timestamp <= bounty.submissionDeadline, "Submission deadline has passed");
        require(msg.sender != bounty.poster, "Poster cannot submit work");
        require(!hasSubmitted[msg.sender], "Work already submitted by this address");
        require(bytes(_workDetails).length > 0, "Work details cannot be empty");

        hasSubmitted[msg.sender] = true;
        submissions.push(Submission({
            submitter: msg.sender,
            workDetails: _workDetails
        }));

        emit WorkSubmitted(msg.sender, _workDetails);
    }

    // Poster selects winner during the decision window
    function selectWinner(address payable _winner) external onlyPoster notPaid nonReentrant {
        require(block.timestamp > bounty.submissionDeadline, "Submission period still active");
        require(block.timestamp <= bounty.decisionDeadline, "Decision deadline has passed");
        require(hasSubmitted[_winner], "Selected address has not submitted work");

        bounty.paid = true;
        bounty.winner = _winner;

        uint256 amount = bounty.reward;
        (bool success, ) = _winner.call{value: amount}("");
        require(success, "Payment to winner failed");

        emit WinnerSelected(_winner, amount);
    }

    // Fallback: if poster abandons bounty after decision deadline, split equally
    function fallbackDistribute() external notPaid nonReentrant {
        require(block.timestamp > bounty.decisionDeadline, "Decision deadline not yet reached");
        require(submissions.length > 0, "No submissions, use reclaim instead");

        bounty.paid = true;

        uint256 count = submissions.length;
        uint256 share = bounty.reward / count;
        require(share > 0, "Reward share too small");

        for (uint256 i = 0; i < count; i++) {
            (bool success, ) = payable(submissions[i].submitter).call{value: share}("");
            require(success, "Transfer to submitter failed");
        }

        // Send any dust from division rounding back to poster
        uint256 remainder = bounty.reward - (share * count);
        if (remainder > 0) {
            (bool remSuccess, ) = bounty.poster.call{value: remainder}("");
            require(remSuccess, "Remainder refund failed");
        }

        emit FallbackDistributed(bounty.reward, share);
    }

    // Poster reclaims reward if no work was submitted after decision deadline
    function reclaim() external onlyPoster notPaid nonReentrant {
        require(block.timestamp > bounty.decisionDeadline, "Decision deadline not yet reached");
        require(submissions.length == 0, "Cannot reclaim - submissions exist");

        bounty.paid = true;
        uint256 amount = bounty.reward;

        (bool success, ) = bounty.poster.call{value: amount}("");
        require(success, "Refund failed");

        emit RefundIssued(bounty.poster, amount);
    }

    // Dynamic status based on deadlines and settlement state
    function getStatus() public view returns (Status) {
        if (bounty.paid) {
            return Status.Paid;
        }
        if (block.timestamp <= bounty.submissionDeadline) {
            return Status.Open;
        }
        if (block.timestamp <= bounty.decisionDeadline) {
            return Status.AwaitingDecision;
        }
        return Status.Expired;
    }

    function getSubmissionsCount() external view returns (uint256) {
        return submissions.length;
    }

    function getAllSubmissions() external view returns (Submission[] memory) {
        return submissions;
    }
}

