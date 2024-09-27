using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GameMainUIManager : Singleton<GameMainUIManager>
{
    [SerializeField] private GameObject Text_Countdown;
    [SerializeField] private GameObject Text_State_correct_Static;
    [SerializeField] private GameObject Text_State_correct;
    [SerializeField] private GameObject Text_State_total_Static;
    [SerializeField] private GameObject Text_State_total;
    [SerializeField] private GameObject Text_lives_Static;
    [SerializeField] private GameObject Text_lives;
    [SerializeField] private GameObject Text_remainingQuestions_Static;
    [SerializeField] private GameObject Text_remainingQuestions;

    //private void Start()
    //{
    //    SwitchToEndlessMode();
    //}

    public void SwitchToEndlessMode()
    {
        SetActiveCountdown(false);
        SetActiveStateCorrectStatic(true);
        SetActiveStateCorrect(true);
        SetActiveStateTotalStatic(true);
        SetActiveStateTotal(true);
        SetActiveLivesStatic(false);
        SetActiveLives(false);
        SetActiveRemainingQuestionsStatic(false);
        SetActiveRemainingQuestions(false);
    }

    public void SwitchToTimedChallengeMode()
    {
        SetActiveCountdown(true);
        SetActiveStateCorrectStatic(true);
        SetActiveStateCorrect(true);
        SetActiveStateTotalStatic(true);
        SetActiveStateTotal(true);
        SetActiveLivesStatic(false);
        SetActiveLives(false);
        SetActiveRemainingQuestionsStatic(false);
        SetActiveRemainingQuestions(false);
    }

    public void SwitchToSpeedRoundMode()
    {
        SetActiveCountdown(true);
        SetActiveStateCorrectStatic(true);
        SetActiveStateCorrect(true);
        SetActiveStateTotalStatic(true);
        SetActiveStateTotal(true);
        SetActiveLivesStatic(false);
        SetActiveLives(false);
        SetActiveRemainingQuestionsStatic(true);
        SetActiveRemainingQuestions(true);
    }

    public void SwitchToTwoLivesMode()
    {
        SetActiveCountdown(false);
        SetActiveStateCorrectStatic(true);
        SetActiveStateCorrect(true);
        SetActiveStateTotalStatic(true);
        SetActiveStateTotal(true);
        SetActiveLivesStatic(true);
        SetActiveLives(true);
        SetActiveRemainingQuestionsStatic(false);
        SetActiveRemainingQuestions(false);
    }

    public void SwitchToReviewMode()
    {
        SetActiveCountdown(false);
        SetActiveStateCorrectStatic(true);
        SetActiveStateCorrect(true);
        SetActiveStateTotalStatic(true);
        SetActiveStateTotal(true);
        SetActiveLivesStatic(false);
        SetActiveLives(false);
        SetActiveRemainingQuestionsStatic(true);
        SetActiveRemainingQuestions(true);
    }

    private void SetActiveCountdown(bool status)
    {
        if (Text_Countdown != null)
        {
            Text_Countdown.SetActive(status);
        }
    }

    private void SetActiveStateCorrectStatic(bool status)
    {
        if (Text_State_correct_Static != null)
        {
            Text_State_correct_Static.SetActive(status);
        }
    }

    private void SetActiveStateCorrect(bool status)
    {
        if (Text_State_correct != null)
        {
            Text_State_correct.SetActive(status);
        }
    }

    private void SetActiveStateTotalStatic(bool status)
    {
        if (Text_State_total_Static != null)
        {
            Text_State_total_Static.SetActive(status);
        }
    }

    private void SetActiveStateTotal(bool status)
    {
        if (Text_State_total != null)
        {
            Text_State_total.SetActive(status);
        }
    }

    private void SetActiveLivesStatic(bool status)
    {
        if (Text_lives_Static != null)
        {
            Text_lives_Static.SetActive(status);
        }
    }

    private void SetActiveLives(bool status)
    {
        if (Text_lives != null)
        {
            Text_lives.SetActive(status);
        }
    }

    private void SetActiveRemainingQuestionsStatic(bool status)
    {
        if (Text_remainingQuestions_Static != null)
        {
            Text_remainingQuestions_Static.SetActive(status);
        }
    }

    private void SetActiveRemainingQuestions(bool status)
    {
        if (Text_remainingQuestions != null)
        {
            Text_remainingQuestions.SetActive(status);
        }
    }
}