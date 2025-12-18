from playwright.sync_api import sync_playwright, expect
import time

def verify_app(page):
    try:
        # 1. Dashboard
        page.goto("http://localhost:5173")
        page.wait_for_selector("text=English Plan", timeout=10000)

        # Screenshot Dashboard
        page.screenshot(path="/home/jules/verification/dashboard.png")
        print("Dashboard screenshot taken.")

        # 2. Lesson Navigation
        # The first strategy is "How About You?". Find the button that is enabled (green/available).
        # We can look for the text "How About You?" and click the container or button near it.
        # Or just click the first button that isn't disabled?
        # Let's try text locator again.

        # Wait a bit for animations
        time.sleep(2)

        page.get_by_text("1. How About You?").click()

        # Wait for Lesson Player
        page.wait_for_url("**/lesson/1")
        time.sleep(2) # wait for video load

        # Screenshot Lesson Start
        page.screenshot(path="/home/jules/verification/lesson_start.png")
        print("Lesson Start screenshot taken.")

        # 3. Complete Steps
        # Video Step -> Continue
        page.get_by_role("button", name="Continue").click()
        time.sleep(0.5)

        # Info Step -> Continue
        page.get_by_role("button", name="Continue").click()
        time.sleep(0.5)

        # Quiz Step -> Select Correct Answer -> Check -> Continue
        # Correct answer for mock data is index 1 ("Na verdade")
        page.get_by_text("Na verdade").click()
        page.get_by_role("button", name="Check").click()
        time.sleep(0.5)
        page.screenshot(path="/home/jules/verification/quiz_feedback.png")
        print("Quiz Feedback screenshot taken.")

        page.get_by_role("button", name="Continue").click()
        time.sleep(0.5)

        # Speech Step
        page.screenshot(path="/home/jules/verification/speech_step.png")
        print("Speech Step screenshot taken.")

    except Exception as e:
        print(f"Error during verification: {e}")
        page.screenshot(path="/home/jules/verification/error_final.png")

if __name__ == "__main__":
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        try:
            verify_app(page)
        except Exception as e:
            print(f"Fatal Error: {e}")
        finally:
            browser.close()
