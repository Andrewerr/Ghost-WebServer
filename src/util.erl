-module(util).
-export([get_time/0, wildcard2regex/1, check_wildcard/2, tup2list/1, sget/2, sget2/2, pretty_addr/1]).
-include("config.hrl").

%% This part of code converts wildcards to regex
%% It is required since erlang can not match wildcards to strings
%% Source: https://stackoverflow.com/questions/17077850/how-to-convert-a-wildcard-pattern-to-regex-in-erlang#17086860
replace(L) when is_list(L) -> lists:reverse(replace(L, wildcard(hd(L)))).

% take care of the first character
replace(L, W = {true, _}) -> replace(L, W, []);
replace(L, W = {false, _}) -> replace(L, W, [$^]).

% take care of the last character
replace([_], {true, R}, Res) -> R ++ Res;
replace([_], {false, R}, Res) -> [$$ | R] ++ Res;
% middle characters
replace([_ | Q], {_, R}, Res) -> replace(Q, wildcard(hd(Q)), R ++ Res).

wildcard($*) -> {true, [$*, $.]};
wildcard($?) -> {true, [$.]};
wildcard($.) -> {true, [$., $\\]};
wildcard(C) -> {false, [C]}.

wildcard2regex(Wildcard) ->
  Regex = replace(Wildcard),
  re:compile(Regex).

tup2list(T) -> tup2list(T, size(T), []).

tup2list(T, 0, Acc) -> Acc;
tup2list(T, N, Acc) -> tup2list(T, N - 1, [element(N, T) | Acc]).

check_wildcard(String, Wildcard) ->
  {ok, Regex} = wildcard2regex(Wildcard),
  case re:run(String, Regex) of
    {match, _} -> true;
    nomatch -> false
  end.
%% Gets standartized time for HTTP
get_time() ->
  Months = #{1 => "Jan",
    2 => "Feb",
    3 => "Mar",
    4 => "Apr",
    5 => "May",
    6 => "Jun",
    7 => "Jul",
    8 => "Aug",
    9 => "Sep",
    10 => "Oct",
    11 => "Nov",
    12 => "Dec"},
  Days = #{1 => "Mon",
    2 => "Tue",
    3 => "Wed",
    4 => "Thu",
    5 => "Fri",
    6 => "Sat",
    7 => "Sun"},
  {{Year, Month, Day}, {Hour, Minute, Second}} = erlang:universaltime(),
  WeekDay = maps:get(calendar:day_of_the_week(Year, Month, Day), Days),
  lists:flatten(io_lib:format("~s, ~2..0w  ~s ~4..0w ~2..0w:~2..0w:~2..0w GMT", [WeekDay, Day, maps:get(Month, Months), Year, Hour, Minute, Second])).
%% Secure map get
sget(Key, Map) ->
  IsKey = maps:is_key(Key, Map),
  if IsKey ->
    maps:get(Key, Map);
    true ->
      {badkey, Key}
  end.

sget2(Key, Map) ->
  IsKey = maps:is_key(Key, Map),
  if IsKey ->
    maps:get(Key, Map);
    true ->
      ""
  end.
pretty_addr(Addr) ->
  lists:flatten(io_lib:format("~p.~p.~p.~p:~p", tup2list(maps:get(addr, Addr)) ++ [maps:get(port, Addr)])).
