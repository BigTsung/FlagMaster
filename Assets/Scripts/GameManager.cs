using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.IO;
using UnityEngine.Localization.Settings;

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

public class GameManager : MonoBehaviour
{
    public enum GameMode
    {
        Endless,
        TimedChallenge,
        SpeedRound,
        TwoLives,
        Review
    }

    public static GameMode currentGameMode = GameMode.Endless;

    [SerializeField] private Color originalColor;
    [SerializeField] private Color correctColor;
    [SerializeField] private Color wrongColor;
    [SerializeField] private Image imageFlag;
    [SerializeField] private Button[] answerButtons;
    [SerializeField] private TextMeshProUGUI countdownText;
    [SerializeField] private TextMeshProUGUI statsCorrectText;
    [SerializeField] private TextMeshProUGUI statsTotalText;
    [SerializeField] private TextMeshProUGUI livesText;
    [SerializeField] private TextMeshProUGUI remainingQuestionsText;

    private List<CountryData> dataList = new List<CountryData>();
    private List<CountryData> selectedCountries;
    private int correctAnswerIndex;
    private bool isWaitingForAnswer = true;
    private Coroutine countdownCoroutine;

    private int correctAnswers = 0;
    private int totalQuestions = 0;
    private int incorrectAnswers = 0;
    private int remainingLives = 2;
    private int totalQuestionLimit = 20;
    private int timeLimit = 10;
    private int totalTimeLimit = 60;
    private float secondToNextQuestion = 1f;

    private List<WrongAnswer> wrongAnswers = new List<WrongAnswer>();
    private HashSet<string> correctAnswerCountries = new HashSet<string>();
    private Dictionary<string, CountryStats> countryStatsDict = new Dictionary<string, CountryStats>();
    private string jsonFilePath;

    private bool loadStatsFromJsonSuccess = false;

    public string sfx_correct = "";
    public string sfx_fail = "";

    void Start()
    {
        InitializeUI();
        SetGameModeRules();
        LoadCountries();
        InitializeFilePath();

        loadStatsFromJsonSuccess = LoadStatsFromJson();

        // UpdateRemainingQuestionsText(); 移动到最后确保更新的题目数量是准确的
        SetupGameMode();  // 确保游戏模式先设置好

        

        GetRandomFourCountries();  // 确保在设置好模式后再生成题目

        UpdateRemainingQuestionsText();  // 更新剩余问题数
    }

    private void InitializeUI()
    {
        statsCorrectText.text = "0";
        statsTotalText.text = "0";
    }

    private void InitializeFilePath()
    {
        jsonFilePath = Path.Combine(Application.persistentDataPath, "CountryStats.json");
        Debug.Log(jsonFilePath);
    }

    private void LoadCountries()
    {
        Countries countries = CountryFlagsLoader.Instance.GetCountries();
        dataList = new List<CountryData>(countries.countries);
    }

    private void SetGameModeRules()
    {
        countdownText.gameObject.SetActive(currentGameMode == GameMode.TimedChallenge || currentGameMode == GameMode.SpeedRound);
        livesText.gameObject.SetActive(currentGameMode == GameMode.TwoLives);

        if (currentGameMode == GameMode.SpeedRound)
        {
            timeLimit = 5;
        }
    }

    private void SetupGameMode()
    {
        switch (currentGameMode)
        {
            case GameMode.Review:
                secondToNextQuestion = 2;
                PrepareReviewMode();
                GameMainUIManager.Instance.SwitchToReviewMode();
                break;
            case GameMode.Endless:
                secondToNextQuestion = 2;
                GameMainUIManager.Instance.SwitchToEndlessMode();
                break;
            case GameMode.TimedChallenge:
                countdownCoroutine = StartCoroutine(StartTotalCountdown());
                secondToNextQuestion = 0.5f;
                GameMainUIManager.Instance.SwitchToTimedChallengeMode();
                break;
            case GameMode.SpeedRound:
                countdownCoroutine = StartCoroutine(StartCountdown());
                secondToNextQuestion = 2;
                GameMainUIManager.Instance.SwitchToSpeedRoundMode();
                break;
            case GameMode.TwoLives:
                UpdateLivesText();
                secondToNextQuestion = 2;
                GameMainUIManager.Instance.SwitchToTwoLivesMode();
                break;
        }
    }

    public void GetRandomFourCountries()
    {
        isWaitingForAnswer = true;
        System.Random rng = new System.Random();
        CountryData correctCountry = null;  // 这里提前声明 correctCountry 变量，确保在整个函数中都可以访问

        // 检查复习模式是否有足够的数据可用
        if (currentGameMode == GameMode.Review)
        {
            if (dataList.Count < 4)
            {
                Debug.LogWarning("Not enough countries in dataList to generate a question.");
                StartCoroutine(WaitAndEndGame());
                return;
            }

            // 从错误率最高的国家中选择
            List<CountryStats> topWrongCountries = GetLowestAccuracyCountries(50);
            if (topWrongCountries.Count == 0)
            {
                Debug.LogWarning("No more countries available for Review Mode.");
                //StartCoroutine(WaitAndEndGame());
                return;
            }

            // 从错题中随机选择一个正确答案
            CountryStats correctCountryStat = topWrongCountries[rng.Next(topWrongCountries.Count)];
            correctCountry = dataList.FirstOrDefault(c => c.cn == correctCountryStat.countryName);

            Debug.Log("correctCountryStat: " + correctCountryStat.countryName);

            if (correctCountry == null)
            {
                Debug.LogWarning("No matching country found for: " + correctCountryStat.countryName);
                StartCoroutine(WaitAndEndGame());
                return;
            }
        }
        else
        {
            // 对于其他模式，使用通用逻辑生成题目
            List<CountryData> availableCountries = dataList.Where(c => !correctAnswerCountries.Contains(c.cn)).ToList();

            if (availableCountries.Count == 0)
            {
                Debug.Log("No more countries available to show.");
                StartCoroutine(WaitAndEndGame());
                return;
            }

            // 随机选择正确答案
            correctCountry = availableCountries[rng.Next(availableCountries.Count)];
            correctAnswerCountries.Add(correctCountry.cn);
        }

        // 随机选择其他三个错误答案
        List<CountryData> otherCountries = dataList
            .Where(c => c.cn != correctCountry.cn)
            .OrderBy(x => rng.Next())
            .Take(3)
            .ToList();

        // 把正确答案加到选项里
        selectedCountries = new List<CountryData>(otherCountries) { correctCountry };
        selectedCountries = selectedCountries.OrderBy(x => rng.Next()).ToList();

        correctAnswerIndex = selectedCountries.IndexOf(correctCountry);  // 这里可以安全使用 correctCountry

        string imgPath = "CountriesFlags/" + selectedCountries[correctAnswerIndex].abb2;
        Sprite flagIcon = Resources.Load<Sprite>(imgPath);
        ApplyFlagEffect(flagIcon);
        UpdateAnswerButtons();
        StartCountdownIfNeeded();
    }

    private void UpdateAnswerButtons()
    {
        for (int i = 0; i < selectedCountries.Count; i++)
        {
            TextMeshProUGUI buttonText = answerButtons[i].GetComponentInChildren<TextMeshProUGUI>();
            buttonText.text = LocalizationSettings.SelectedLocale.Identifier.Code == "en"
                ? selectedCountries[i].en
                : selectedCountries[i].cn;
            buttonText.color = originalColor;
            answerButtons[i].interactable = true;
            ApplyButtonEffect(answerButtons[i], i);
        }
    }

    private void StartCountdownIfNeeded()
    {
        if (currentGameMode == GameMode.SpeedRound && countdownCoroutine != null)
        {
            StopCoroutine(countdownCoroutine);
            countdownCoroutine = StartCoroutine(StartCountdown());
        }
    }

    public void OnCountrySelected(int index)
    {
        if (!isWaitingForAnswer) return;

        isWaitingForAnswer = false;
        answerButtons[index].interactable = false;
        HandleAnswerSelection(index);
        UpdateStatsText();

        if (currentGameMode == GameMode.SpeedRound && totalQuestionLimit - totalQuestions <= 0)
        {
            StartCoroutine(WaitAndEndGame());
        }
        else
        {
            StartCoroutine(NextQuestion());
        }
    }

    private void HandleAnswerSelection(int index)
    {
        TextMeshProUGUI selectedButtonText = answerButtons[index].GetComponentInChildren<TextMeshProUGUI>();
        TextMeshProUGUI correctButtonText = answerButtons[correctAnswerIndex].GetComponentInChildren<TextMeshProUGUI>();

        totalQuestions++;
        UpdateRemainingQuestionsText();

        if (index == correctAnswerIndex)
        {
            AudioManager.Instance.PlaySFX(sfx_correct);
            correctButtonText.color = correctColor;
            correctAnswers++;
            UpdateCountryStats(selectedCountries[correctAnswerIndex].cn, true);
        }
        else
        {
            HandleIncorrectAnswer(selectedButtonText, correctButtonText, index);
        }

        SaveStatsToJson();
    }

    private void HandleIncorrectAnswer(TextMeshProUGUI selectedButtonText, TextMeshProUGUI correctButtonText, int index)
    {
        incorrectAnswers++;
        AudioManager.Instance.PlaySFX(sfx_fail);
        correctButtonText.color = correctColor;

        // 设置错误答案的颜色
        if (index >= 0 && index < selectedCountries.Count)
        {
            selectedButtonText.color = wrongColor;

            string correctAnswer = selectedCountries[correctAnswerIndex].cn;
            string playerAnswer = selectedCountries[index].cn;
            wrongAnswers.Add(new WrongAnswer(correctAnswer, correctAnswer, playerAnswer));

            UpdateCountryStats(correctAnswer, false);  // 每次答错都更新国家统计数据
        }

        //SaveStatsToJson();

        if (currentGameMode == GameMode.TwoLives)
        {
            remainingLives--;
            UpdateLivesText();

            if (remainingLives <= 0)
            {
                StartCoroutine(WaitAndEndGame());
            }
        }
    }
    //private void SaveStats()
    //{
    //    CountryStatsList statsList = new CountryStatsList { statsList = countryStatsDict.Values.ToList() };
    //    string json = JsonUtility.ToJson(statsList, true);
    //    File.WriteAllText(jsonFilePath, json);
    //}

    //private bool LoadStats()
    //{
    //    if (!File.Exists(jsonFilePath)) return false;

    //    string json = File.ReadAllText(jsonFilePath);
    //    CountryStatsList statsList = JsonUtility.FromJson<CountryStatsList>(json);
    //    countryStatsDict = statsList.statsList.ToDictionary(stat => stat.countryName, stat => stat);


    //    Debug.Log("WHAT:" + countryStatsDict.Count);
    //    return countryStatsDict.Count > 0;
    //}


    private void SaveStatsToJson()
    {
        Debug.Log(" SaveStatsToJson ");

        CountryStatsList statsList = new CountryStatsList();
        statsList.statsList = countryStatsDict.Values.ToList();

        string json = JsonUtility.ToJson(statsList, true);
        File.WriteAllText(jsonFilePath, json);  // 保存到持久化路径中的JSON文件

        Debug.Log("Stats saved to JSON: " + json);
    }

    private bool LoadStatsFromJson()
    {
        if (File.Exists(jsonFilePath))
        {
            string json = File.ReadAllText(jsonFilePath);
            CountryStatsList statsList = JsonUtility.FromJson<CountryStatsList>(json);
            countryStatsDict = statsList.statsList.ToDictionary(stat => stat.countryName, stat => stat);

            Debug.Log("Stats loaded from JSON: " + json);
            return true;
        }
        else
        {
            Debug.LogWarning("No stats file found.");
            return false;
        }
    }

    private void UpdateRemainingQuestionsText()
    {
        remainingQuestionsText.text = (totalQuestionLimit - totalQuestions).ToString();
    }

    private void UpdateStatsText()
    {
        statsCorrectText.text = correctAnswers.ToString();
        statsTotalText.text = totalQuestions.ToString();
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
    }



    public List<CountryStats> GetLowestAccuracyCountries(int count)
    {
        // 按错误率从高到低排序，并返回前count个国家
        return countryStatsDict.Values.OrderBy(stat => stat.accuracy).Take(count).ToList();
    }

    private void PrepareReviewMode()
    {
        // 从 JSON 文件加载统计数据
        if (!loadStatsFromJsonSuccess)
        {
            Debug.LogWarning("No stats data found in JSON.");
            StartCoroutine(WaitAndEndGame(0f));  // 如果加载失败，直接结束游戏
            return;
        }

        // 获取错误率最高的前50个国家
        List<CountryStats> topWrongCountries = GetLowestAccuracyCountries(50);

        // 如果没有任何错误率国家，结束游戏
        if (topWrongCountries.Count == 0)
        {
            Debug.LogWarning("No countries with wrong answers found for Review Mode.");
            StartCoroutine(WaitAndEndGame());
            return;
        }

        // 随机选择其中一个作为正确答案
        System.Random rng = new System.Random();
        CountryStats correctCountryStat = topWrongCountries[rng.Next(topWrongCountries.Count)];
        CountryData correctCountry = dataList.FirstOrDefault(c => c.cn == correctCountryStat.countryName);

        if (correctCountry == null)
        {
            Debug.LogWarning("No matching country found for: " + correctCountryStat.countryName);
            StartCoroutine(WaitAndEndGame());
            return;
        }

        // 选择其他三个随机国家作为错误答案
        List<CountryData> otherCountries = dataList
            .Where(c => c.cn != correctCountry.cn)  // 排除正确答案
            .OrderBy(x => rng.Next())
            .Take(3)
            .ToList();

        // 将正确答案和其他国家组成选项
        selectedCountries = new List<CountryData>(otherCountries) { correctCountry };
        selectedCountries = selectedCountries.OrderBy(x => rng.Next()).ToList();

        correctAnswerIndex = selectedCountries.IndexOf(correctCountry);

        // 显示国旗和答案按钮
        string imgPath = "CountriesFlags/" + selectedCountries[correctAnswerIndex].abb2;
        Sprite flagIcon = Resources.Load<Sprite>(imgPath);
        ApplyFlagEffect(flagIcon);
        UpdateAnswerButtons();
    }

    private IEnumerator StartTotalCountdown()
    {
        int timeRemaining = totalTimeLimit;
        while (timeRemaining >= 0)
        {
            countdownText.text = timeRemaining.ToString();
            yield return new WaitForSeconds(1);
            timeRemaining--;
        }

        HandleCountdownEnd();
    }

    private void HandleCountdownEnd()
    {
        AudioManager.Instance.PlaySFX(sfx_fail);

        TextMeshProUGUI correctButtonText = answerButtons[correctAnswerIndex].GetComponentInChildren<TextMeshProUGUI>();
        correctButtonText.color = correctColor;

        UpdateStatsText();
        StartCoroutine(WaitAndEndGame());
    }

    private IEnumerator StartCountdown()
    {
        if (countdownCoroutine != null) StopCoroutine(countdownCoroutine);

        int timeRemaining = timeLimit;
        countdownText.text = timeRemaining.ToString();

        while (timeRemaining > 0)
        {
            yield return new WaitForSeconds(1);
            countdownText.text = (--timeRemaining).ToString();
        }

        HandleTimeOut();
    }

    private void HandleTimeOut()
    {
        if (isWaitingForAnswer)
        {
            isWaitingForAnswer = false;
            incorrectAnswers++;
            totalQuestions++;

            UpdateRemainingQuestionsText();
            AudioManager.Instance.PlaySFX(sfx_fail);

            TextMeshProUGUI correctButtonText = answerButtons[correctAnswerIndex].GetComponentInChildren<TextMeshProUGUI>();
            correctButtonText.color = correctColor;

            UpdateStatsText();
            StartCoroutine(NextQuestion());
        }
    }

    private IEnumerator WaitAndEndGame(float second = 1f)
    {
        yield return new WaitForSeconds(second);
        EndGame();
    }

    private void EndGame()
    {
        isWaitingForAnswer = false;
        FindObjectOfType<PauseManager>().PauseGame(true);
    }

    private void UpdateLivesText()
    {
        livesText.text = remainingLives.ToString();
    }

    public void RestartGame()
    {
        ResetGameStats();
        LoadCountries();
        correctAnswerCountries.Clear();

        UpdateStatsText();
        GetRandomFourCountries();

        if (currentGameMode == GameMode.TimedChallenge)
        {
            countdownCoroutine = StartCoroutine(StartTotalCountdown());
        }
        else if (currentGameMode == GameMode.SpeedRound)
        {
            countdownCoroutine = StartCoroutine(StartCountdown());
        }
    }

    private void ResetGameStats()
    {
        totalQuestions = 0;
        incorrectAnswers = 0;
        correctAnswers = 0;
        wrongAnswers.Clear();
    }

    public void ClearAppearedCountries()
    {
        correctAnswerCountries.Clear();
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
}