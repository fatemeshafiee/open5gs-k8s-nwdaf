from enum import Enum
from pydantic import BaseModel, Field
from typing import Union

class FailureCodeEnum(str, Enum):
    UNAVAILABLE_ML_MODEL = "UNAVAILABLE_ML_MODEL"

class FailureCode(BaseModel):
    description: str = "Represents the failure code."
    failure_code: Union[FailureCodeEnum, str] = Field(
        ..., 
        description="Enum for known failure codes, or a custom string for future extensions."
    )