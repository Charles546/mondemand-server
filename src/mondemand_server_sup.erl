-module (mondemand_server_sup).

-behaviour (supervisor).

%% API
-export([start_link/0]).

%% supervisor callbacks
-export([init/1]). 

%%====================================================================
%% API functions
%%====================================================================
%% @spec start_link() -> ServerRet
%% @doc API for starting the supervisor.
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%%====================================================================
%% supervisor callbacks
%%====================================================================
%% @spec init([]) -> SupervisorTree
%% @doc supervisor callback.
init([]) ->
  Dispatch =
    case mondemand_server_config:dispatch () of
      [] -> exit (no_dispatch_list);
      L -> L
    end,
  error_logger:info_msg ("Dispatch ~p",[Dispatch]),

  BackendsToStart = mondemand_server_config:backends_to_start (),

  ToStart =
    {
      { one_for_one, 10, 10 },
      [
        {
          mondemand_server,
          { mondemand_server, start_link, [Dispatch] },
          permanent,
          2000,
          worker,
          [ mondemand_server ]
        }
        |
        [ begin
            BackendConfig =
              case application:get_env (mondemand_server, BackendModule) of
                { ok, T } -> T;
                undefined -> []
              end,
            { BackendModule,
              { BackendModule, start_link, [BackendConfig] },
              permanent,
              2000,
              worker,
              [ BackendModule ]
            }
          end
          || BackendModule
          <- BackendsToStart
        ]
      ]
    },
  error_logger:info_msg ("Starting ~p",[ToStart]),
  { ok, ToStart }.

%%--------------------------------------------------------------------
%%% Test functions
%%--------------------------------------------------------------------
-ifdef(HAVE_EUNIT).
-include_lib("eunit/include/eunit.hrl").
-endif.

-ifdef(EUNIT).

-endif.
