using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.UI;
using TMPro;

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
    private List<CountryData> dataList = new List<CountryData>();
    private int correctAnswerIndex;
    private bool isWaitingForAnswer = true;
    private Coroutine countdownCoroutine;
    private int timeLimit = 10;
    private int selectedEffectIndex = 0;

    [SerializeField] private Image imageFlag;
    [SerializeField] private Button[] answerButtons;
    [SerializeField] private TextMeshProUGUI countdownText;
    [SerializeField] private TextMeshProUGUI statsText;

    private int totalQuestions = 0;
    private int incorrectAnswers = 0;

    // 創建一個 List 來保存錯誤題目的信息
    private List<WrongAnswer> wrongAnswers = new List<WrongAnswer>();

    private int flagEffectIndex = 1;
    private int buttonEffectIndex = 7;

    public string sfx_correct = "";
    public string sfx_fail = "";

    void Start()
    {
        Countries countries = CountryFlagsLoader.Instance.GetCountries();
        dataList = new List<CountryData>(countries.countries);
        GetRandomFourCountries();

        SwitchCountdownEffect(2); // Start with effect index 2 (e.g., rotate effect)
    }

    public void GetRandomFourCountries()
    {
        isWaitingForAnswer = true;
        System.Random rng = new System.Random();
        dataList = dataList.OrderBy(x => rng.Next()).ToList();

        List<CountryData> selectedCountries = dataList.Take(4).ToList();
        correctAnswerIndex = rng.Next(4);

        string imgPath = "CountriesFlags/" + selectedCountries[correctAnswerIndex].abb2;
        Sprite flagIcon = Resources.Load<Sprite>(imgPath);

        ApplyFlagEffect(flagIcon);

        for (int i = 0; i < selectedCountries.Count; i++)
        {
            TextMeshProUGUI buttonText = answerButtons[i].GetComponentInChildren<TextMeshProUGUI>();
            buttonText.text = selectedCountries[i].cn;
            buttonText.color = Color.white;
            answerButtons[i].interactable = true;

            ApplyButtonEffect(answerButtons[i], i);
        }

        if (countdownCoroutine != null) StopCoroutine(countdownCoroutine);
        countdownCoroutine = StartCoroutine(StartCountdown());
    }

    private void ApplyFlagEffect(Sprite flagIcon)
    {
        imageFlag.sprite = flagIcon;
        imageFlag.color = new Color(1f, 1f, 1f, 0f);
        LeanTween.alpha(imageFlag.rectTransform, 1f, 1f);
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

        StopCoroutine(countdownCoroutine);

        // 更新總答題數
        totalQuestions++;

        if (index == correctAnswerIndex)
        {
            AudioManager.Instance.PlaySFX(sfx_correct);
            correctButtonText.color = Color.green;
        }
        else
        {
            // 答錯時更新錯誤數
            incorrectAnswers++;
            AudioManager.Instance.PlaySFX(sfx_fail);
            correctButtonText.color = Color.green;
            selectedButtonText.color = Color.red;

            // 記錄錯誤的題目和相關信息
            string correctAnswer = dataList[correctAnswerIndex].cn;
            string playerAnswer = dataList[index].cn;
            wrongAnswers.Add(new WrongAnswer(dataList[correctAnswerIndex].cn, correctAnswer, playerAnswer));
        }

        // 更新統計數據的顯示
        UpdateStatsText();

        Debug.Log(wrongAnswers);

        StartCoroutine(NextQuestion());
    }

    private void UpdateStatsText()
    {
        // 更新右上角顯示的 "錯誤數/總答題數"
        statsText.text = incorrectAnswers + " / " + totalQuestions;
    }

    private IEnumerator NextQuestion()
    {
        yield return new WaitForSeconds(2);
        GetRandomFourCountries();
    }

    private IEnumerator StartCountdown()
    {
        int timeRemaining = timeLimit;
        while (timeRemaining >= 0)
        {
            countdownText.text = timeRemaining.ToString();

            ScaleCountdownEffect();

            if (timeRemaining <= 3)
            {
                FlashCountdownEffect();
            }

            yield return new WaitForSeconds(1);
            timeRemaining--;
        }

        if (isWaitingForAnswer)
        {
            TextMeshProUGUI correctButtonText = answerButtons[correctAnswerIndex].GetComponentInChildren<TextMeshProUGUI>();
            correctButtonText.color = Color.green;
            isWaitingForAnswer = false;
            StartCoroutine(NextQuestion());
        }
    }

    private void ApplyCountdownEffect()
    {
        Debug.Log("Applying effect: " + selectedEffectIndex);
    
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
        float percentage = (float)timeLimit / 10f;
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
}