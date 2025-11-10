from typing import List, Optional, Literal
from pydantic import BaseModel, HttpUrl, validator


ContractType = Literal["b2b", "uop", "uz", "uod", "other"]
WorkMode = Literal["remote", "hybrid", "office", "unspecified"]


class Salary(BaseModel):
    raw: str
    min: Optional[float] = None
    max: Optional[float] = None
    currency: Optional[str] = None
    period: Optional[str] = None      # "month", "year", "hour", etc.
    contract_type: Optional[ContractType] = None


class JobOffer(BaseModel):
    url: HttpUrl
    title: str
    company: Optional[str] = None
    location: Optional[str] = None

    work_mode: WorkMode = "unspecified"
    tech_stack: List[str] = []
    salaries: List[Salary] = []

    must_have: Optional[str] = None
    nice_to_have: Optional[str] = None
    responsibilities: Optional[str] = None
    offer_description: Optional[str] = None

    error: Optional[str] = None

    @validator("tech_stack", pre=True)
    def normalize_tech_stack(cls, v):
        if not v:
            return []
        if isinstance(v, list):
            return [s.strip() for s in v if s and s.strip()]
        return [x.strip() for x in str(v).replace(",", " ").split() if x.strip()]

    @validator("work_mode", pre=True, always=True)
    def detect_work_mode(cls, v, values):
        if v and v != "unspecified":
            return v

        blob = " ".join(
            str(values.get(k) or "")
            for k in ("offer_description", "responsibilities", "location")
        ).lower()

        if any(x in blob for x in ["zdaln", "remote"]):
            return "remote"
        if "hybrid" in blob or "hybryd" in blob:
            return "hybrid"
        if any(x in blob for x in ["on-site", "biuro", "office", "stacjonar"]):
            return "office"
        return "unspecified"
