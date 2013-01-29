{application, ddup,
 [{description, "ddup"},
  {vsn, "0.01"},
  {modules, [
    ddup,
    ddup_app,
    ddup_sup,
    ddup_web,
    ddup_deps
  ]},
  {registered, []},
  {mod, {ddup_app, []}},
  {env, []},
  {applications, [kernel, stdlib, crypto]}]}.
