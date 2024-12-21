// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract LearnToEarnStreaming {
    address public owner;
    uint256 public expertRewardRate; // Reward rate for experts per question
    uint256 public viewerRewardRate; // Reward rate for viewers per interaction

    struct Expert {
        address expertAddress;
        uint256 rewardsEarned;
        bool isRegistered;
    }

    struct Question {
        uint256 questionId;
        address askedBy;
        address expert;
        string content;
        bool answered;
        uint256 rewardPaid;
    }

    mapping(address => Expert) public experts;
    mapping(uint256 => Question) public questions;

    uint256 public questionCount;

    event QuestionAsked(uint256 questionId, address askedBy, string content);
    event QuestionAnswered(uint256 questionId, address expert);
    event RewardsClaimed(address expert, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier onlyRegisteredExpert() {
        require(experts[msg.sender].isRegistered, "Not a registered expert");
        _;
    }

    constructor(uint256 _expertRewardRate, uint256 _viewerRewardRate) {
        owner = msg.sender;
        expertRewardRate = _expertRewardRate;
        viewerRewardRate = _viewerRewardRate;
    }

    function registerExpert(address _expertAddress) external onlyOwner {
        require(!experts[_expertAddress].isRegistered, "Already registered");
        experts[_expertAddress] = Expert(_expertAddress, 0, true);
    }

    function askQuestion(string memory _content) external payable {
        require(msg.value > 0, "Reward must be greater than 0");

        questionCount++;
        questions[questionCount] = Question(
            questionCount,
            msg.sender,
            address(0),
            _content,
            false,
            msg.value
        );

        emit QuestionAsked(questionCount, msg.sender, _content);
    }

    function answerQuestion(uint256 _questionId) external onlyRegisteredExpert {
        Question storage question = questions[_questionId];
        require(!question.answered, "Question already answered");
        require(question.rewardPaid == 0, "Reward already paid");

        question.answered = true;
        question.expert = msg.sender;

        // Reward the expert
        experts[msg.sender].rewardsEarned += question.rewardPaid;
        question.rewardPaid = 0;

        emit QuestionAnswered(_questionId, msg.sender);
    }

    function claimRewards() external onlyRegisteredExpert {
        uint256 amount = experts[msg.sender].rewardsEarned;
        require(amount > 0, "No rewards to claim");

        experts[msg.sender].rewardsEarned = 0;
        payable(msg.sender).transfer(amount);

        emit RewardsClaimed(msg.sender, amount);
    }

    function updateRewardRates(uint256 _expertRewardRate, uint256 _viewerRewardRate) external onlyOwner {
        expertRewardRate = _expertRewardRate;
        viewerRewardRate = _viewerRewardRate;
    }
}
