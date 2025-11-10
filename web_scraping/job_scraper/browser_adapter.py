from abc import ABC, abstractmethod
from typing import Optional
from urllib.parse import urljoin


class AbstractBrowserAdapter(ABC):
    @abstractmethod
    def open(self): ...
    @abstractmethod
    def close(self): ...
    @abstractmethod
    def new_page(self):
        """Return page/ctx handle."""
    @abstractmethod
    def goto(self, page, url: str): ...
    @abstractmethod
    def click_if_exists(self, page, selector: str): ...
    @abstractmethod
    def query_selector_all(self, page, selector: str):
        """Return list of native elements from underlying engine."""
    @abstractmethod
    def get_attr(self, element, name: str) -> Optional[str]: ...
    @abstractmethod
    def eval(self, page, script: str): ...
    @abstractmethod
    def wait(self, page, ms: int): ...

    def resolve_url(self, base_url: str, href: str) -> str:
        return urljoin(str(base_url), href)


# --- Playwright implementation ---

from playwright.sync_api import sync_playwright


class PlaywrightAdapter(AbstractBrowserAdapter):
    def __init__(self, headless: bool = True, user_agent: Optional[str] = None):
        self.headless = headless
        self.user_agent = user_agent or (
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/122.0.0.0 Safari/537.36"
        )

    def open(self):
        self._p = sync_playwright().start()
        self._browser = self._p.chromium.launch(headless=self.headless)
        self._context = self._browser.new_context(
            user_agent=self.user_agent,
            locale="pl-PL",
            timezone_id="Europe/Warsaw",
        )

    def close(self):
        self._context.close()
        self._browser.close()
        self._p.stop()

    def new_page(self):
        return self._context.new_page()

    def goto(self, page, url: str):
        page.goto(url, wait_until="domcontentloaded")

    def click_if_exists(self, page, selector: str):
        try:
            el = page.query_selector(selector)
            if el and el.is_visible():
                el.click()
        except:
            pass

    def query_selector_all(self, page, selector: str):
        return page.query_selector_all(selector)

    def get_attr(self, element, name: str) -> Optional[str]:
        try:
            return element.get_attribute(name)
        except:
            return None

    def eval(self, page, script: str):
        return page.evaluate(script)

    def wait(self, page, ms: int):
        page.wait_for_timeout(ms)
