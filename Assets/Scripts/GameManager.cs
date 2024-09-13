using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.UI;
using TMPro;
using UnityEngine.SceneManagement;

[System.Serializable]
public class WrongAnswer
{
    public string countryName;    // 錯誤題目的國家名稱
    public string correctAnswer;  // 正確答案
    public string playerAnswer;   // 玩家選擇的答案

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
        TwoLives  // 新增的 Two Lives 模式
    }

    public static GameMode currentGameMode = GameMode.Endless;  // 保存當前的遊戲模式

    private List<CountryData> dataList = new List<CountryData>();
    private int correctAnswerIndex;
    private bool isWaitingForAnswer = true;
    private Coroutine countdownCoroutine;
    private int totalTimeLimit = 60;  // 總時間限制 (僅限 TimedChallenge mode)
    private int timeLimit = 10;  // 單一題目的時間限制 (Speed Round mode)
    private int selectedEffectIndex = 0;

    [SerializeField] private Color originalColor;
    [SerializeField] private Color correctColor;
    [SerializeField] private Color wrongColor;
    [SerializeField] private Image imageFlag;
    [SerializeField] private Button[] answerButtons;
    [SerializeField] private TextMeshProUGUI countdownText;
    [SerializeField] private TextMeshProUGUI statsText;
    [SerializeField] private TextMeshProUGUI livesText;  // 顯示剩餘命數的 UI
    [SerializeField] private float secondToNextQuestion = 1f;

    private int totalQuestions = 0;
    private int incorrectAnswers = 0;
    private int correctAnswers = 0;
    private int remainingLives = 2;  // Two Lives 模式下的初始命數

    // 創建一個 List 來保存錯誤題目的信息
    private List<WrongAnswer> wrongAnswers = new List<WrongAnswer>();

    private int flagEffectIndex = 1;
    private int buttonEffectIndex = 7;

    // 追踪已出現的國家
    private HashSet<string> appearedCountries = new HashSet<string>();

    public string sfx_correct = "";
    public string sfx_fail = "";

    void Start()
    {
        statsText.text = "答對題數:" + 0 + "\n" + "總答題數:" + 0;

        // 設置不同模式的遊戲規則
        SetGameModeRules();

        Countries countries = CountryFlagsLoader.Instance.GetCountries();
        dataList = new List<CountryData>(countries.countries);

        // 減少 dataList 中的可用國家數量來加速測試
        //dataList = dataList.Take(10).ToList();  // 減少可用的國家數量

        GetRandomFourCountries();

        if (currentGameMode == GameMode.Endless)
        {
            secondToNextQuestion = 2;
        }
        else if (currentGameMode == GameMode.TimedChallenge)
        {
            countdownCoroutine = StartCoroutine(StartTotalCountdown()); // 開始總計時
            secondToNextQuestion = 0.5f;
        }
        else if (currentGameMode == GameMode.SpeedRound)
        {
            countdownCoroutine = StartCoroutine(StartCountdown()); // 每題計時
            secondToNextQuestion = 2;
        }
        else if (currentGameMode == GameMode.TwoLives)
        {
            UpdateLivesText();  // 顯示初始命數
            secondToNextQuestion = 2;
        }
    }

    // 設置不同模式的遊戲規則
    private void SetGameModeRules()
    {
        Debug.Log(currentGameMode);
        if (currentGameMode == GameMode.TimedChallenge)
        {
            countdownText.gameObject.SetActive(true);  // 顯示倒計時
            livesText.gameObject.SetActive(false);  // 隱藏命數顯示
        }
        else if (currentGameMode == GameMode.SpeedRound)
        {
            timeLimit = 5; // 每一題限時 5 秒
            countdownText.gameObject.SetActive(true);  // 顯示倒計時
            livesText.gameObject.SetActive(false);  // 隱藏命數顯示
        }
        else if (currentGameMode == GameMode.TwoLives)
        {
            remainingLives = 2;  // 設置初始命數為 2
            countdownText.gameObject.SetActive(false); // 隱藏倒計時
            livesText.gameObject.SetActive(true);  // 顯示剩餘命數
        }
        else
        {
            countdownText.gameObject.SetActive(false); // 隱藏倒計時 (Endless 模式)
            livesText.gameObject.SetActive(false);  // 隱藏命數顯示
        }
    }

    public void GetRandomFourCountries()
    {
        isWaitingForAnswer = true;
        System.Random rng = new System.Random();
        dataList = dataList.OrderBy(x => rng.Next()).ToList();

        // 過濾掉已經出現過的正確答案
        List<CountryData> availableCountries = dataList.Where(c => !appearedCountries.Contains(c.cn)).ToList();

        // 如果可用國家數少於 4，說明已經出現過所有國家，則重新開始
        if (availableCountries.Count < 4)
        {
            EndGame();
            return;
        }

        List<CountryData> selectedCountries = availableCountries.Take(4).ToList();
        correctAnswerIndex = rng.Next(4);

        // 將新的正確答案加入已出現的國家列表
        appearedCountries.Add(selectedCountries[correctAnswerIndex].cn);

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
            countdownCoroutine = StartCoroutine(StartCountdown()); // 重新開始每題的倒計時
        }

        // 在 GetRandomFourCountries 方法內部
        Debug.Log("Correct Answer: " + selectedCountries[correctAnswerIndex].cn);

        // 打印已出現過的國家
        Debug.Log("Appeared Countries: " + string.Join(", ", appearedCountries));
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
        if (!isWaitingForAnswer) return;  // 避免多次選擇

        isWaitingForAnswer = false;  // 防止重複執行
        answerButtons[index].interactable = false;

        TextMeshProUGUI selectedButtonText = answerButtons[index].GetComponentInChildren<TextMeshProUGUI>();
        TextMeshProUGUI correctButtonText = answerButtons[correctAnswerIndex].GetComponentInChildren<TextMeshProUGUI>();

        // 更新總答題數，確保只在第一次回答時更新
        totalQuestions++;

        if (index == correctAnswerIndex)
        {
            AudioManager.Instance.PlaySFX(sfx_correct);
            correctButtonText.color = correctColor;
            correctAnswers++;
        }
        else
        {
            // 答錯時更新錯誤數
            incorrectAnswers++;
            AudioManager.Instance.PlaySFX(sfx_fail);
            correctButtonText.color = correctColor;
            selectedButtonText.color = wrongColor;

            // 記錄錯誤的題目和相關信息
            string correctAnswer = dataList[correctAnswerIndex].cn;
            string playerAnswer = dataList[index].cn;
            wrongAnswers.Add(new WrongAnswer(dataList[correctAnswerIndex].cn, correctAnswer, playerAnswer));
        }

        // 更新統計數據的顯示
        UpdateStatsText();

        StartCoroutine(NextQuestion());
    }

    private void UpdateStatsText()
    {
        // 更新右上角顯示的 "錯誤數/總答題數"
        statsText.text = "答對題數:" + correctAnswers + "\n" + "總答題數:" + totalQuestions;
    }

    private void UpdateLivesText()
    {
        livesText.text = "剩餘生命: " + remainingLives;
    }

    private IEnumerator NextQuestion()
    {
        yield return new WaitForSeconds(secondToNextQuestion);
        GetRandomFourCountries();
    }

    // 整體計時器：TimedChallenge 模式下的總時間計時
    private IEnumerator StartTotalCountdown()
    {
        int timeRemaining = totalTimeLimit;
        while (timeRemaining > 0)
        {
            countdownText.text = timeRemaining.ToString();
            yield return new WaitForSeconds(1);
            timeRemaining--;
        }

        EndGame();  // 計時結束後結束遊戲
    }

    // 每題倒計時 (Speed Round 模式)
    private IEnumerator StartCountdown()
    {
        int timeRemaining = timeLimit;
        while (timeRemaining > 0)
        {
            countdownText.text = timeRemaining.ToString();
            yield return new WaitForSeconds(1);
            timeRemaining--;
        }

        // 確保顯示倒數為 0
        countdownText.text = "0";

        // 當時間到且還沒有選擇答案，標記該題為答錯
        if (isWaitingForAnswer)
        {
            isWaitingForAnswer = false;  // 防止多次更新

            // 記為答錯，並顯示正確答案
            incorrectAnswers++;
            totalQuestions++;  // 確保總答題數只更新一次

            TextMeshProUGUI correctButtonText = answerButtons[correctAnswerIndex].GetComponentInChildren<TextMeshProUGUI>();
            correctButtonText.color = correctColor;

            // 更新統計數據
            UpdateStatsText();

            // 自動跳到下一題
            StartCoroutine(NextQuestion());
        }
    }

    private void EndGame()
    {
        isWaitingForAnswer = false;
        Debug.Log("Game over.");

        // 暫停遊戲並顯示 "Time's up" 文本
        FindObjectOfType<PauseManager>().PauseGame(true);
    }

    private void ApplyCountdownEffect()
    {
        switch (selectedEffectIndex)
        {
            case 0:
                ScaleCountdownEffect();
                break;
            case 1:
                ColorFadeCountdownEffect();
                break;
            case 2:
                RotateCountdownEffect();
                break;
            case 3:
                FlashCountdownEffect();
                break;
            default:
                ScaleCountdownEffect();
                break;
        }
    }

    public void SwitchCountdownEffect(int effectIndex)
    {
        selectedEffectIndex = effectIndex;
    }

    private void ScaleCountdownEffect()
    {
        countdownText.transform.localScale = Vector3.one;
        LeanTween.scale(countdownText.gameObject, new Vector3(1.5f, 1.5f, 1f), 0.5f).setEaseOutBounce();
    }

    private void ColorFadeCountdownEffect()
    {
        Color startColor = Color.green;
        Color endColor = Color.red;
        float percentage = (float)totalTimeLimit / 10f;
        countdownText.color = Color.Lerp(startColor, endColor, percentage);
    }

    private void RotateCountdownEffect()
    {
        countdownText.transform.rotation = Quaternion.identity;
        LeanTween.rotateZ(countdownText.gameObject, 360f, 1f).setEaseInOutCubic();
    }

    private void FlashCountdownEffect()
    {
        Color currentColor = countdownText.color;
        countdownText.faceColor = new Color(currentColor.r, currentColor.g, currentColor.b, 1f);
        LeanTween.value(countdownText.gameObject, 1f, 0f, 0.5f).setLoopPingPong(1).setOnUpdate((float val) => {
            currentColor.a = val;
            countdownText.faceColor = currentColor;
        });
    }

    // 用來返回錯誤的題目列表，便於複習功能使用
    public List<WrongAnswer> GetWrongAnswers()
    {
        return wrongAnswers;
    }

    // Restart function
    public void RestartGame()
    {
        // 清空統計數據和錯誤題目列表
        totalQuestions = 0;
        incorrectAnswers = 0;
        correctAnswers = 0;
        wrongAnswers.Clear();

        // 重新加載所有國家
        Countries countries = CountryFlagsLoader.Instance.GetCountries();
        dataList = new List<CountryData>(countries.countries);

        // 重設命數
        if (currentGameMode == GameMode.TwoLives)
        {
            remainingLives = 2;
            UpdateLivesText();
        }

        // 更新統計數據顯示
        UpdateStatsText();

        // 開始新的一輪答題
        GetRandomFourCountries();

        // 如果是 TimedChallenge 模式，重新開始計時
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
            countdownCoroutine = StartCoroutine(StartCountdown());  // 為 Speed Round 模式重新開始每題計時
        }
    }

    public void ClearAppearedCountries()
    {
        appearedCountries.Clear();
    }
}