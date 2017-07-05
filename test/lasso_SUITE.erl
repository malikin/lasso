-module(lasso_SUITE).
-include_lib("common_test/include/ct.hrl").
-export([check_get/1, check_post/1, check_delete/1]).
-export([all/0, init_per_testcase/2, end_per_testcase/2]).

all() -> [check_get, check_post, check_delete].

init_per_testcase(_, Config) ->
  Port = 8080,
  ListenerName = my_http_listener,
  application:ensure_all_started(lasso),
  Dispatch = cowboy_router:compile([
                                    {'_', [
                                           {"/", hello_handler, []},
                                           {"/echo", post_handler, []},
                                           {"/entity", delete_handler, []}
                                          ]}
                                   ]),
  {ok, _} = cowboy:start_http(ListenerName, 5,
                               [{port, Port}],
                               [{env, [{dispatch, Dispatch}]}]
                              ),
  ConnPid = lasso:open(Port, []),
  Config2 = [{listener_name, ListenerName} | Config],
  [{conn, ConnPid} | Config2].

end_per_testcase(_, Config) ->
  ConnPid = ?config(conn, Config),
  lasso:close(ConnPid),
  cowboy:stop_listener(?config(listener_name, Config)),
  ok.

check_get(Config) ->
  ConnPid = ?config(conn, Config),
  {_, _, Body} = lasso:get(ConnPid, <<"/">>),
  Body = <<"Hello Erlang!">>.

check_post(Config) ->
  ConnPid = ?config(conn, Config),
  RequestBody = <<"{\"msg\": \"Hello world!\"}">>,
  {_, _, Body} = lasso:post(ConnPid, <<"/echo">>, [{<<"content-type">>, <<"application/json">>}], RequestBody),
  RequestBody = Body.

check_delete(Config) ->
  ConnPid = ?config(conn, Config),
  {_, _, Body} = lasso:delete(ConnPid, <<"/entity">>),
  Body = <<"">>.
