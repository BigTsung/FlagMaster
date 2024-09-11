using UnityEngine;
using UnityEngine.SceneManagement;

public class PauseManager : MonoBehaviour
{
    public GameObject pauseMenuUI;  // 暫停UI的 Panel
    private bool isPaused = false;  // 紀錄目前是否處於暫停狀態
    public float animationDuration = 0.5f;  // 動畫持續時間

    // 當按下暫停按鈕時觸發
    public void TogglePauseGame()
    {
        if (isPaused)
        {
            ResumeGame();
        }
        else
        {
            PauseGame();
        }
    }

    // 暫停遊戲
    public void PauseGame()
    {
        pauseMenuUI.SetActive(true);

        // 將 UI 設置為屏幕外位置
        pauseMenuUI.GetComponent<RectTransform>().anchoredPosition = new Vector2(0, -Screen.height);

        // 移動到屏幕中央
        LeanTween.moveY(pauseMenuUI.GetComponent<RectTransform>(), 0, animationDuration).setEase(LeanTweenType.easeOutQuad);

        LeanTween.delayedCall(animationDuration, () =>
        {
            Time.timeScale = 0f;
            isPaused = true;
        });
    }

    // 恢復遊戲
    public void ResumeGame()
    {
        Time.timeScale = 1f;

        // 從屏幕滑出
        LeanTween.moveY(pauseMenuUI.GetComponent<RectTransform>(), -Screen.height, animationDuration).setEase(LeanTweenType.easeInQuad).setOnComplete(() =>
        {
            pauseMenuUI.SetActive(false);
            isPaused = false;
        });
    }

    // 重新啟動當前遊戲場景
    public void RestartGame()
    {
        Time.timeScale = 1f;  // 恢復時間
        SceneManager.LoadScene(SceneManager.GetActiveScene().name);  // 重新加載當前場景
    }

    // 返回到主場景
    public void ReturnToMainScene()
    {
        Time.timeScale = 1f;  // 恢復時間
        SceneManager.LoadScene("Page_Main");  // 加載主場景 (MainMenu)
    }

    // 選擇退出遊戲或返回主選單
    public void QuitGame()
    {
        Time.timeScale = 1f;  // 確保時間恢復正常
        Application.Quit();  // 退出遊戲
    }
}