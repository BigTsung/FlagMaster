using UnityEngine;
using UnityEngine.UI;

public class RecordPanelManager : MonoBehaviour
{
    [SerializeField] private string pressedSFX = "ui_menu_button_click_19";
    [SerializeField] private Button backButton;
    public void OnBackButtonPressed()
    {
        UIEffect defaultEffect = new UIEffect(sfx: pressedSFX);
        defaultEffect.PlayButtonFeedback(backButton, false, () => {
            Debug.Log("button name:" + backButton.name);
            MainUIManager.Instance.ToggleRecordPanel();
        });
    }
}
