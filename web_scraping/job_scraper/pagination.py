from typing import List, Set
from .config import SiteConfig
from .browser_adapter import AbstractBrowserAdapter


class BasePaginationStrategy:
    def collect_links(self, page, browser: AbstractBrowserAdapter, cfg: SiteConfig) -> List[str]:
        raise NotImplementedError


class NextPageStrategy(BasePaginationStrategy):
    def collect_links(self, page, browser: AbstractBrowserAdapter, cfg: SiteConfig) -> List[str]:
        links: Set[str] = set()

        while True:
            cards = browser.query_selector_all(page, cfg.listing_container_selector)
            for card in cards:
                if cfg.offer_link_selector == "&self":
                    href = browser.get_attr(card, "href")
                else:
                    a = card.query_selector(cfg.offer_link_selector)
                    href = a.get_attribute("href") if a else None
                if href:
                    links.add(browser.resolve_url(cfg.base_url, href))

            next_sel = cfg.pagination.next_button_selector
            if not next_sel:
                break

            btns = browser.query_selector_all(page, next_sel)
            if not btns:
                break

            btns[0].click()
            browser.wait(page, 800)

        return sorted(links)


class InfiniteScrollStrategy(BasePaginationStrategy):
    def collect_links(self, page, browser: AbstractBrowserAdapter, cfg: SiteConfig) -> List[str]:
        links: Set[str] = set()
        last_height = 0

        for _ in range(cfg.pagination.infinite_scroll_max_steps):
            cards = browser.query_selector_all(page, cfg.listing_container_selector)
            for card in cards:
                if cfg.offer_link_selector == "&self":
                    href = browser.get_attr(card, "href")
                else:
                    a = card.query_selector(cfg.offer_link_selector)
                    href = a.get_attribute("href") if a else None
                if href:
                    links.add(browser.resolve_url(cfg.base_url, href))

            browser.eval(page, "window.scrollTo(0, document.body.scrollHeight)")
            browser.wait(page, int(cfg.pagination.infinite_scroll_pause * 1000))

            new_height = browser.eval(page, "document.body.scrollHeight")
            if new_height == last_height:
                break
            last_height = new_height

        return sorted(links)
