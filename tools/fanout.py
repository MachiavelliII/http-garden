"""This is where the code for actually talking to the servers lives."""

from typing import Callable

from http1 import (
    HTTPRequest,
    HTTPResponse,
)
from targets import Server
from util import eager_pmap

def trace[A, R](server: Server, f: Callable[[A], R]) -> Callable[[A], tuple[R, frozenset[int]]]:
    def result(*args, **kwargs):
        server.clear_trace()
        return (f(*args, **kwargs), server.collect_trace())

    return result


def traced_fanout(
    data: list[bytes], servers: list[Server]
) -> list[tuple[list[HTTPRequest | HTTPResponse], frozenset[int]]]:
    return eager_pmap(lambda server: trace(server, server.parsed_roundtrip)(data), servers)


def fanout(
    data: list[bytes], servers: list[Server]
) -> list[list[HTTPRequest | HTTPResponse]]:
    return eager_pmap(
        lambda server: server.parsed_roundtrip(data),
        servers,
    )


def unparsed_fanout(data: list[bytes], servers: list[Server]) -> list[list[bytes]]:
    return eager_pmap(
        lambda t: t[0].unparsed_roundtrip(t[1]),
        list(zip(servers, [data for _ in range(len(servers))])),
    )
