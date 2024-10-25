using System;
using System.Collections.Generic;

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
        accuracy = totalAttempts > 0 ? (float)correctAnswers / totalAttempts * 100f : 0f;
    }
}

[System.Serializable]
public class CountryStatsList
{
    public List<CountryStats> statsList = new List<CountryStats>();
}