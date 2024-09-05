using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class GameManager : MonoBehaviour
{
    private List<CountryData> dataList = new List<CountryData>();
    private int correctAnswerIndex;
    private bool isWaitingForAnswer = true; // Controls whether waiting for player's answer
    private Coroutine countdownCoroutine; // To save the countdown coroutine
    private int timeLimit = 10; // Countdown time in seconds

    [SerializeField] private Image imageFlag;
    [SerializeField] private Button[] answerButtons; // Array of buttons for answer options
    [SerializeField] private TextMeshProUGUI countdownText; // Text to display countdown

    void Start()
    {
        Countries countries = CountryFlagsLoader.Instance.GetCountries();
        dataList = new List<CountryData>(countries.countries);
        GetRandomFourCountries(); // Load the first question on start
    }

    public void GetRandomFourCountries()
    {
        isWaitingForAnswer = true; // Set to waiting for player's answer
        System.Random rng = new System.Random();
        dataList = dataList.OrderBy(x => rng.Next()).ToList();

        List<CountryData> selectedCountries = dataList.Take(4).ToList();
        correctAnswerIndex = rng.Next(4); // Randomly select the correct answer

        string imgPath = "CountriesFlags/" + selectedCountries[correctAnswerIndex].abb2;
        Sprite flagIcon = Resources.Load<Sprite>(imgPath);
        imageFlag.sprite = flagIcon;

        // Set country names for each button
        for (int i = 0; i < selectedCountries.Count; i++)
        {
            TextMeshProUGUI buttonText = answerButtons[i].GetComponentInChildren<TextMeshProUGUI>();
            buttonText.text = selectedCountries[i].cn;
            buttonText.color = Color.white; // Set text color to white
            answerButtons[i].interactable = true; // Enable the buttons
        }

        // Start countdown timer
        if (countdownCoroutine != null) StopCoroutine(countdownCoroutine); // Stop the previous countdown
        countdownCoroutine = StartCoroutine(StartCountdown());
    }

    public void OnCountrySelected(int index)
    {
        if (!isWaitingForAnswer) return; // Prevent multiple clicks

        isWaitingForAnswer = false; // Player has selected an answer
        answerButtons[index].interactable = false; // Disable the selected button

        TextMeshProUGUI selectedButtonText = answerButtons[index].GetComponentInChildren<TextMeshProUGUI>();
        TextMeshProUGUI correctButtonText = answerButtons[correctAnswerIndex].GetComponentInChildren<TextMeshProUGUI>();

        StopCoroutine(countdownCoroutine); // Stop the countdown when player selects an answer

        if (index == correctAnswerIndex)
        {
            correctButtonText.color = Color.green; // Display the correct answer in green
        }
        else
        {
            correctButtonText.color = Color.green; // Display the correct answer in green
            selectedButtonText.color = Color.red; // Display the wrong answer in red
        }

        StartCoroutine(NextQuestion()); // Move to the next question after 2 seconds
    }

    private IEnumerator NextQuestion()
    {
        yield return new WaitForSeconds(2); // Wait for 2 seconds
        GetRandomFourCountries(); // Load the next question
    }

    private IEnumerator StartCountdown()
    {
        int timeRemaining = timeLimit;
        while (timeRemaining > 0)
        {
            countdownText.text = "Countdown: " + timeRemaining.ToString(); // Display remaining time
            yield return new WaitForSeconds(1);
            timeRemaining--;
        }

        // Time's up, show the correct answer and move to the next question
        if (isWaitingForAnswer)
        {
            TextMeshProUGUI correctButtonText = answerButtons[correctAnswerIndex].GetComponentInChildren<TextMeshProUGUI>();
            correctButtonText.color = Color.green; // Show correct answer in green
            isWaitingForAnswer = false;
            StartCoroutine(NextQuestion()); // Move to the next question after 2 seconds
        }
    }

    void Update()
    {
        // No logic needed to execute every frame
    }
}