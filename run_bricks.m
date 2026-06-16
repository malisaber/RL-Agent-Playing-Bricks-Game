root_dir = fileparts(mfilename("fullpath"));
src_dir = fullfile(root_dir, "src");

addpath(src_dir);
run(fullfile(src_dir, "main.m"));
