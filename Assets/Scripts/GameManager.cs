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
    private bool isWaitingForAnswer = true;
    private Coroutine countdownCoroutine;
    private int timeLimit = 10;
    private int selectedEffectIndex = 0;

    [SerializeField] private Image imageFlag;
    [SerializeField] private Button[] answerButtons;
    [SerializeField] private TextMeshProUGUI countdownText;

    private int flagEffectIndex = 1;
    private int buttonEffectIndex = 7;

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

        if (index == correctAnswerIndex)
        {
            correctButtonText.color = Color.green;
        }
        else
        {
            correctButtonText.color = Color.green;
            selectedButtonText.color = Color.red;
        }

        StartCoroutine(NextQuestion());
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
                Debug.Log("Applying scale effect");
                ScaleCountdownEffect();
                break;
            case 1:
                Debug.Log("Applying color fade effect");
                ColorFadeCountdownEffect();
                break;
            case 2:
                Debug.Log("Applying rotate effect");
                RotateCountdownEffect();
                break;
            case 3:
                Debug.Log("Applying flash effect");
                FlashCountdownEffect();
                break;
            default:
                Debug.Log("Applying default scale effect");
                ScaleCountdownEffect();
                break;
        }
    }

    public void SwitchCountdownEffect(int effectIndex)
    {
        selectedEffectIndex = effectIndex;
        Debug.Log("Switched to effect index: " + selectedEffectIndex);
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
        Debug.Log("Color fade applied with percentage: " + percentage + ", color: " + countdownText.color);
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
}