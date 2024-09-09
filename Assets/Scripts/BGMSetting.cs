using UnityEngine;

public class BGMSetting : MonoBehaviour
{
    [SerializeField] private string bgmName; // The name of the BGM to be played in this scene

    void Start()
    {
        // When the scene starts, play the BGM with the specified name
        if (!string.IsNullOrEmpty(bgmName))
        {
            AudioManager.Instance.PlayBGM(bgmName);
        }
        else
        {
            Debug.LogWarning("No BGM name specified for this scene.");
        }
    }
}