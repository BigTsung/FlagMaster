using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.UI;
using TMPro;
using UnityEngine.SceneManagement;
using System.IO;

[System.Serializable]
public class WrongAnswer
{
    public string countryName;
    public string correctAnswer;
    public string playerAnswer;

    public WrongAnswer(string countryName, string correctAnswer, string playerAnswer)
    {
        this.countryName = countryName;
        this.correctAnswer = correctAnswer;
        this.playerAnswer = playerAnswer;
    }
}

[System.Serializable]
public class CountryStats
{
    public string countryName;
    public int correctAnswers;
    public int totalAttempts;
    public float accuracy;

    public CountryStats(string name)
    {
        countryName = name;
        correctAnswers = 0;
        totalAttempts = 0;
        accuracy = 0f;
    }

    public void UpdateAccuracy()
    {
        if (totalAttempts > 0)
        {
            accuracy = (float)correctAnswers / totalAttempts * 100f;
        }
        else
        {
            accuracy = 0f;
        }
    }
}

[System.Serializable]
public class CountryStatsList
{
    public List<CountryStats> statsList = new List<CountryStats>();
}

public class GameManager : MonoBehaviour
{
    public enum GameMode
    {
        Endless,
        TimedChallenge,
        SpeedRound,
        TwoLives,
        Review // 新增 Review 模式
    }

    public static GameMode currentGameMode = GameMode.Endless;

    private List<CountryData> dataList = new List<CountryData>();
    private int correctAnswerIndex;
    private bool isWaitingForAnswer = true;
    private Coroutine countdownCoroutine;
    private int totalTimeLimit = 60;
    private int timeLimit = 10;
    private int selectedEffectIndex = 0;

    [SerializeField] private Color originalColor;
    [SerializeField] private Color correctColor;
    [SerializeField] private Color wrongColor;
    [SerializeField] private Image imageFlag;
    [SerializeField] private Button[] answerButtons;
    [SerializeField] private TextMeshProUGUI countdownText;
    [SerializeField] private TextMeshProUGUI statsText;
    [SerializeField] private TextMeshProUGUI livesText;
    [SerializeField] private float secondToNextQuestion = 1f;

    private int totalQuestions = 0;
    private int incorrectAnswers = 0;
    private int correctAnswers = 0;
    private int remainingLives = 2;

    private List<WrongAnswer> wrongAnswers = new List<WrongAnswer>();
    private HashSet<string> correctAnswerCountries = new HashSet<string>();

    private Dictionary<string, CountryStats> countryStatsDict = new Dictionary<string, CountryStats>();
    private string jsonFilePath;

    public string sfx_correct = "";
    public string sfx_fail = "";

    void Start()
    {
        statsText.text = "答對題數:" + 0 + "\n" + "總答題數:" + 0;

        SetGameModeRules();

        Countries countries = CountryFlagsLoader.Instance.GetCountries();
        dataList = new List<CountryData>(countries.countries);

        jsonFilePath = Path.Combine(Application.persistentDataPath, "CountryStats.json");

        Debug.Log("Application.persistentDataPath: " + Application.persistentDataPath);

        LoadStats();

        Debug.Log("currentGameMode: " + currentGameMode);

   
        GetRandomFourCountries();

        if (currentGameMode == GameMode.Review)
        {
            secondToNextQuestion = 2;
            PrepareReviewMode();
        }
        else if (currentGameMode == GameMode.Endless)
        {
            secondToNextQuestion = 2;
        }
        else if (currentGameMode == GameMode.TimedChallenge)
        {
            countdownCoroutine = StartCoroutine(StartTotalCountdown());
            secondToNextQuestion = 0.5f;
        }
        else if (currentGameMode == GameMode.SpeedRound)
        {
            countdownCoroutine = StartCoroutine(StartCountdown());
            secondToNextQuestion = 2;
        }
        else if (currentGameMode == GameMode.TwoLives)
        {
            UpdateLivesText();
            secondToNextQuestion = 2;
        }
    }

    private void SetGameModeRules()
    {
        if (currentGameMode == GameMode.TimedChallenge)
        {
            countdownText.gameObject.SetActive(true);
            livesText.gameObject.SetActive(false);
        }
        else if (currentGameMode == GameMode.SpeedRound)
        {
            timeLimit = 5;
            countdownText.gameObject.SetActive(true);
            livesText.gameObject.SetActive(false);
        }
        else if (currentGameMode == GameMode.TwoLives)
        {
            remainingLives = 2;
            countdownText.gameObject.SetActive(false);
            livesText.gameObject.SetActive(true);
        }
        else
        {
            countdownText.gameObject.SetActive(false);
            livesText.gameObject.SetActive(false);
        }
    }

    public void GetRandomFourCountries()
    {
        isWaitingForAnswer = true;
        System.Random rng = new System.Random();

        // 過濾掉已經作為正確答案出現過的國家
        List<CountryData> availableCountries = dataList.Where(c => !correctAnswerCountries.Contains(c.cn)).ToList();

        if (availableCountries.Count == 0)
        {
            EndGame();
            return;
        }

        // 隨機選取一個正確答案從 availableCountries 中
        CountryData correctCountry = availableCountries[rng.Next(availableCountries.Count)];

        // 將正確答案加入到已出現過的列表
        correctAnswerCountries.Add(correctCountry.cn);

        // 剩下的 3 個錯誤答案從 dataList 中排除正確答案，並隨機選擇
        List<CountryData> otherCountries = dataList.Where(c => c.cn != correctCountry.cn).OrderBy(x => rng.Next()).Take(3).ToList();

        // 把正確答案加到選項裡
        List<CountryData> selectedCountries = new List<CountryData>(otherCountries);
        selectedCountries.Add(correctCountry);

        // 隨機排列選項
        selectedCountries = selectedCountries.OrderBy(x => rng.Next()).ToList();

        correctAnswerIndex = selectedCountries.IndexOf(correctCountry);

        string imgPath = "CountriesFlags/" + selectedCountries[correctAnswerIndex].abb2;
        Sprite flagIcon = Resources.Load<Sprite>(imgPath);

        ApplyFlagEffect(flagIcon);

        for (int i = 0; i < selectedCountries.Count; i++)
        {
            TextMeshProUGUI buttonText = answerButtons[i].GetComponentInChildren<TextMeshProUGUI>();
            buttonText.text = selectedCountries[i].cn;
            buttonText.color = originalColor;
            answerButtons[i].interactable = true;

            ApplyButtonEffect(answerButtons[i], i);
        }

        if (currentGameMode == GameMode.SpeedRound)
        {
            if (countdownCoroutine != null) StopCoroutine(countdownCoroutine);
            countdownCoroutine = StartCoroutine(StartCountdown());
        }

        Debug.Log("Correct Answer: " + correctCountry.cn);
        Debug.Log("Appeared Countries: " + string.Join(", ", correctAnswerCountries));
    }

    private void ApplyFlagEffect(Sprite flagIcon)
    {
        imageFlag.sprite = flagIcon;
        imageFlag.color = new Color(1f, 1f, 1f, 0f);
        LeanTween.alpha(imageFlag.rectTransform, 1f, 0.75f);
    }

    private void ApplyButtonEffect(Button button, int index)
    {
        button.transform.localScale = Vector3.zero;
        LeanTween.scale(button.gameObject, Vector3.one, 1f).setEaseOutBack().setDelay(0.1f * index);
    }

    public void OnCountrySelected(int index)
    {
        if (!isWaitingForAnswer) return;

        isWaitingForAnswer = false;
        answerButtons[index].interactable = false;

        TextMeshProUGUI selectedButtonText = answerButtons[index].GetComponentInChildren<TextMeshProUGUI>();
        TextMeshProUGUI correctButtonText = answerButtons[correctAnswerIndex].GetComponentInChildren<TextMeshProUGUI>();

        totalQuestions++;

        if (index == correctAnswerIndex)
        {
            AudioManager.Instance.PlaySFX(sfx_correct);
            correctButtonText.color = correctColor;
            correctAnswers++;
            UpdateCountryStats(dataList[correctAnswerIndex].cn, true);
        }
        else
        {
            incorrectAnswers++;
            AudioManager.Instance.PlaySFX(sfx_fail);
            correctButtonText.color = correctColor;
            selectedButtonText.color = wrongColor;

            string correctAnswer = dataList[correctAnswerIndex].cn;
            string playerAnswer = dataList[index].cn;
            wrongAnswers.Add(new WrongAnswer(dataList[correctAnswerIndex].cn, correctAnswer, playerAnswer));

            UpdateCountryStats(dataList[correctAnswerIndex].cn, false);
        }

        UpdateStatsText();
        StartCoroutine(NextQuestion());
    }

    private void UpdateStatsText()
    {
        statsText.text = "答對題數:" + correctAnswers + "\n" + "總答題數:" + totalQuestions;
    }

    private IEnumerator NextQuestion()
    {
        yield return new WaitForSeconds(secondToNextQuestion);
        GetRandomFourCountries();
    }

    private void UpdateCountryStats(string countryName, bool isCorrect)
    {
        if (!countryStatsDict.ContainsKey(countryName))
        {
            countryStatsDict[countryName] = new CountryStats(countryName);
        }

        if (isCorrect)
        {
            countryStatsDict[countryName].correctAnswers++;
        }

        countryStatsDict[countryName].totalAttempts++;

        countryStatsDict[countryName].UpdateAccuracy();

        SaveStats();
    }

    private void SaveStats()
    {
        CountryStatsList statsList = new CountryStatsList();
        statsList.statsList = countryStatsDict.Values.ToList();

        string json = JsonUtility.ToJson(statsList, true);
        File.WriteAllText(jsonFilePath, json);

        Debug.Log("Stats saved: " + json);
    }

    private void LoadStats()
    {
        if (File.Exists(jsonFilePath))
        {
            string json = File.ReadAllText(jsonFilePath);
            CountryStatsList statsList = JsonUtility.FromJson<CountryStatsList>(json);

            countryStatsDict = statsList.statsList.ToDictionary(stat => stat.countryName, stat => stat);

            Debug.Log("Stats loaded: " + json);
        }
        else
        {
            Debug.Log("No stats file found, starting fresh.");
        }
    }

    public List<CountryStats> GetLowestAccuracyCountries(int count)
    {
        return countryStatsDict.Values.OrderBy(stat => stat.accuracy).Take(count).ToList();
    }

    private void PrepareReviewMode()
    {
        // 從錯誤次數多的國家中選取，最多選取 50 個國家
        List<CountryStats> topWrongCountries = GetLowestAccuracyCountries(50);

        Debug.Log("topWrongCountries.Count: " + topWrongCountries.Count);

        // 確保選擇題目來源是 dataList 中存在的國家，並匹配正確的國家名
        dataList = topWrongCountries
            .Select(stat => dataList.FirstOrDefault(country =>
                country.cn.Trim().ToLower() == stat.countryName.Trim().ToLower()))
            .Where(country => country != null)
            .ToList();

        Debug.Log("dataList.Count: " + dataList.Count);

        if (dataList.Count == 0)
        {
            Debug.LogWarning("No valid countries found for Review Mode.");
            EndGame();
        }
        else
        {
            GetRandomFourCountries(); // 從選定的國家中開始出題
        }
    }

    private IEnumerator StartTotalCountdown()
    {
        int timeRemaining = totalTimeLimit;
        while (timeRemaining > 0)
        {
            countdownText.text = timeRemaining.ToString();
            yield return new WaitForSeconds(1);
            timeRemaining--;
        }

        EndGame();
    }

    private IEnumerator StartCountdown()
    {
        int timeRemaining = timeLimit;
        while (timeRemaining > 0)
        {
            countdownText.text = timeRemaining.ToString();
            yield return new WaitForSeconds(1);
            timeRemaining--;
        }

        countdownText.text = "0";

        if (isWaitingForAnswer)
        {
            isWaitingForAnswer = false;
            incorrectAnswers++;
            totalQuestions++;

            TextMeshProUGUI correctButtonText = answerButtons[correctAnswerIndex].GetComponentInChildren<TextMeshProUGUI>();
            correctButtonText.color = correctColor;

            UpdateStatsText();
            StartCoroutine(NextQuestion());
        }
    }

    private void EndGame()
    {
        isWaitingForAnswer = false;
        PauseManager pauseManager = FindObjectOfType<PauseManager>();
        Debug.Log("pauseManager: " + pauseManager);
        pauseManager.PauseGame(true);

        Debug.Log("EndGame");
    }

    private void UpdateLivesText()
    {
        livesText.text = "剩餘生命: " + remainingLives;
    }

    public void RestartGame()
    {
        totalQuestions = 0;
        incorrectAnswers = 0;
        correctAnswers = 0;
        wrongAnswers.Clear();

        Countries countries = CountryFlagsLoader.Instance.GetCountries();
        dataList = new List<CountryData>(countries.countries);

        correctAnswerCountries.Clear();

        UpdateStatsText();
        GetRandomFourCountries();

        if (currentGameMode == GameMode.TimedChallenge)
        {
            if (countdownCoroutine != null)
            {
                StopCoroutine(countdownCoroutine);
            }
            countdownCoroutine = StartCoroutine(StartTotalCountdown());
        }
        else if (currentGameMode == GameMode.SpeedRound)
        {
            countdownCoroutine = StartCoroutine(StartCountdown());
        }
    }

    public void ClearAppearedCountries()
    {
        correctAnswerCountries.Clear();
    }
}