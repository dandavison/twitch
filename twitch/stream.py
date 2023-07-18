from abc import ABC


class Stream(ABC):
    pass


class AvailabilityStrategy(ABC):
    def check_availability(self, stream: Stream):
        ...


class AbstractFileBasedStream(Stream):
    pass


class AbstractFileBasedAvailabilityStrategy(AvailabilityStrategy):
    def check_availability(self, stream: AbstractFileBasedStream):
        ...
