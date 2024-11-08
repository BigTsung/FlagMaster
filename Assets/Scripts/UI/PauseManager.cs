using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;  // 用於處理 Text 和 Button

public class PauseManager : MonoBehaviour
{
    [SerializeField] private string pressedSFX = "ui_menu_button_click_19";
    [SerializeField] private float feedbackDuration = 0.15f;  // 按鈕縮放動畫持續時間
    [SerializeField] private Vector3 pressedScale = new Vector3(0.9f, 0.9f, 0.9f);  // 按鈕按下時的縮放

    public GameObject pauseMenuUI;  // 暫停UI的 Panel
    public GameObject timeUpTextGameObject;         // "Time's up" 的文本
    public GameObject backButtonGameObject;       // "Back" 按鈕

    [SerializeField] private Button continueButton;
    [SerializeField] private Button restartButton;
    [SerializeField] private Button backButton;

    public string togglePauseMenuUISFX = "";
    private bool isPaused = false;  // 紀錄目前是否處於暫停狀態
    public float animationDuration = 0.5f;  // 動畫持續時間

    //private void Awake()
    //{
    //    //pauseMenuUI.SetActive(false);
    //    Debug.Log("WHAT");
    //}

    void Start()
    {
        // 確保 "Time's up" 文本初始為隱藏
        timeUpTextGameObject.SetActive(false);
    }

    // 當按下暫停按鈕時觸發
    public void TogglePauseGame()
    {
        Debug.Log("TogglePauseGame");
        
        UIEffect defaultEffect = new UIEffect();
        defaultEffect.PlayButtonFeedback(continueButton, true, () => {
            Debug.Log("button name:" + continueButton.name);

            if (isPaused)
            {
                ResumeGame();
            }
            else
            {
                PauseGame(false);  // 普通暫停，不顯示 "Time's up"
            }
        });
    }

    // 暫停遊戲 (當 timeIsUp 為 true 時，顯示 "Time's up" 並隱藏 Back 按鈕)
    public void PauseGame(bool timeIsUp)
    {
        //pauseMenuUI.SetActive(true);

        if (timeIsUp)
        {
            timeUpTextGameObject.SetActive(true);   // 顯示 "Time's up" 文本
            backButtonGameObject.SetActive(false);  // 隱藏 "Back" 按鈕
        }
        else
        {
            timeUpTextGameObject.SetActive(false);  // 隱藏 "Time's up" 文本
            backButtonGameObject.SetActive(true);   // 顯示 "Back" 按鈕
        }

        // 將 UI 設置為屏幕外位置
        //pauseMenuUI.GetComponent<RectTransform>().anchoredPosition = new Vector2(0, -Screen.height);
        pauseMenuUI.GetComponent<SlidePanel>().TogglePanel();
        //Debug.Log("animationDuration:" + animationDuration);

        // 移動到屏幕中央
        //LeanTween.moveY(pauseMenuUI.GetComponent<RectTransform>(), 0, animationDuration).setEase(LeanTweenType.easeOutQuad);

        //LeanTween.delayedCall(animationDuration, () =>
        //{
        //    Time.timeScale = 0f;
        //    isPaused = true;
        //});
    }

    // 恢復遊戲
    public void ResumeGame()
    {
        Time.timeScale = 1f;
        pauseMenuUI.GetComponent<SlidePanel>().TogglePanel();
        // 從屏幕滑出
        //LeanTween.moveY(pauseMenuUI.GetComponent<RectTransform>(), -Screen.height, animationDuration).setEase(LeanTweenType.easeInQuad).setOnComplete(() =>
        //{
        //    pauseMenuUI.SetActive(false);
        //    isPaused = false;
        //});
    }

    // 重新啟動當前遊戲場景
    public void RestartGame()
    {
        UIEffect defaultEffect = new UIEffect();
        defaultEffect.PlayButtonFeedback(restartButton, true, () => {
            Debug.Log("button name:" + restartButton.name);

            Time.timeScale = 1f;  // 恢復時間
            SceneManager.LoadScene(SceneManager.GetActiveScene().name);  // 重新加載當前場景
        });
    }

    // 返回到主場景
    public void ReturnToMainScene()
    {
        UIEffect defaultEffect = new UIEffect();
        defaultEffect.PlayButtonFeedback(backButton, true, () => {
            Debug.Log("button name:" + backButton.name);

            Time.timeScale = 1f;  // 恢復時間
                                  // 清空已出現的國家
            FindObjectOfType<GameManager>().ClearAppearedCountries();
            SceneManager.LoadScene("Page_Main");  // 加載主場景 (MainMenu)
        });
    }

    // 選擇退出遊戲或返回主選單
    public void QuitGame()
    {
        Time.timeScale = 1f;  // 確保時間恢復正常
        Application.Quit();  // 退出遊戲
    }
}