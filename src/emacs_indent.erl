-module(emacs_indent).
-export([main/1]).
-mode(compile).

main([Filename]) ->
	indent_file(Filename);
main(["-r", TargetDirectory]) ->
	indent_files(TargetDirectory);
main(_) ->
	io:format("Usage: emacs_indent [FILE] | [-r TARGET_DIRECTORY]~n").

%% TODO: make this parellel
indent_files(TargetDirectory) ->
	lists:foreach(
		fun indent_file/1,
		lists:map(
			fun (D) -> TargetDirectory ++ "/" ++ D end,
			filelib:wildcard("**/*.*rl", TargetDirectory)
		)
	).

indent_file(Filename) ->
	Dirname = filename:dirname(filename:absname(Filename)),
	Basename = filename:basename(Filename),
	EmacsExtensionDir = get_emacs_ext_dir(),
	file:set_cwd(Dirname),
	CommandStr = io_lib:format(
		"emacs --batch --eval ~s",
		[elisp(Basename, EmacsExtensionDir)]
	),
	io:format(
		"indenting ~s/~s with emacs...~n",
		[Dirname, Basename]
	),
	% io:format("\t~s~n", [CommandStr]),
	os:cmd(CommandStr).

get_emacs_ext_dir() ->
	case get(emacs_extension_dir) of
	undefined ->
		hd(filelib:wildcard(code:lib_dir() ++ "/tools-*/emacs"));
	EmacsExtensionDir ->
		EmacsExtensionDir
	end.

elisp(Filename, EmacsExtensionDir) ->
	[
	"\"(progn ",
	"(find-file \\\"", Filename, "\\\") ",
	"(setq load-path (cons \\\"",
	EmacsExtensionDir,
	"\\\" load-path)) "
	"(require 'erlang-start) ",
	"(erlang-mode) ",
	"(erlang-indent-current-buffer) ",
	"(delete-trailing-whitespace) ",
	"(untabify (point-min) (point-max)) ",
	% "(tabify (point-min) (point-max)) ",
	"(write-region (point-min) (point-max) \\\"",
	Filename,
	"\\\") "
	"(kill-emacs) ",
	")\""
	].

