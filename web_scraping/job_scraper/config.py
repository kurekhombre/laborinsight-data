from typing import List, Optional, Literal
from pydantic import BaseModel, AnyHttpUrl, model_validator


PaginationMode = Literal["next", "infinite"]


class JobFieldSelectors(BaseModel):
    title: str
    company: Optional[str] = None
    location: Optional[str] = None
    salary: Optional[str] = None
    tech_stack: Optional[str] = None
    description: Optional[str] = None
    must_have: Optional[str] = None
    nice_to_have: Optional[str] = None
    responsibilities: Optional[str] = None


class PaginationConfig(BaseModel):
    mode: PaginationMode
    next_button_selector: Optional[str] = None
    infinite_scroll_pause: float = 1.0
    infinite_scroll_max_steps: int = 40

    @model_validator(mode="after")
    def validate_config(self):
        if self.mode == "next" and not self.next_button_selector:
            raise ValueError("next_button_selector is required for mode='next'")
        return self


class SiteConfig(BaseModel):
    name: str
    base_url: AnyHttpUrl

    listing_container_selector: str
    offer_link_selector: str               # może być specjalnie "&self"

    cookie_accept_selector: Optional[str] = None
    extra_click_selectors: List[str] = []
    geo_fix_script: Optional[str] = None

    pagination: PaginationConfig
    fields: JobFieldSelectors
