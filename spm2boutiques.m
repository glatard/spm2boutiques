% Requires toolbox "JSON Lab"
%
% This function writes a Boutiques tool descriptor from an SPM configuration file.
%
% Parameters:
%  * object:          an object built from an SPM configuration file, for instance "spm_cfg_smooth".
%  * json_file_name:  file name where to write the Boutiques JSON descriptor.

function spm2boutiques(object,json_file_name)
  
  % Required tool and tool input fields
  required_tool_fields  = { "tag", "name", "val", "help"};
  required_input_fields = { "tag", "name", "val", "help"};
  
  % Consistency checks on object
  if(!isobject(object))
    error("Argument is not an object")
  endif  
  
  % Check required tool fields
  for field = required_tool_fields 
    if(!isIn(fieldnames(object),field))
      error(sprintf("Object has no field named %s",field{1}))
    endif
  endfor
  
  % Build struct that will contain the Boutiques descriptor
  boutiques_desc.name               = object.name;
  boutiques_desc.description        = object.help{1}; % FIXME: is {1} really correct? Or shall we concatenate all the elements in object.help?
  boutiques_desc.("schema-version") = "0.4";
  boutiques_desc.("tool-version")   = spm('Version'); 
  boutiques_desc.("command-line")   = "TODO"; % FIXME. See comment in Boutiques' Github #64, how is the command line built?
    % Container
  container_image.type  = "docker";
  container_image.image = "spm"; % FIXME: put actual image containing SPM on DockerHub
  boutiques_desc.("container-image")= container_image;
  
  % Go through inputs
  ninputs=0;
  for input = object.val
    ninputs++;
    % Consistency checks on input
    if(!iscell(input))
      error("Input is not a cell") % This should never happen
    endif
    if(columns(input)!=1)
      error("Input has more than 1 column") % This should never happen
    endif
    % Check required input fields
    for field = required_input_fields 
      if(!isIn(fieldnames(input{1}),field))
        error(sprintf("Input has no field named %s",field{1}))
      endif
    endfor
    
    % Set input fields
    boutiques_input               = cell();           % Clear input from previous loop iteration
    boutiques_input.id            = input{1}.tag;
    boutiques_input.name          = input{1}.name; 
    boutiques_input.type          = "String"; % FIXME. At the very least we need to distinguish files from strings.
    boutiques_input.description   = input{1}.help{1};
    boutiques_input.("value-key") = sprintf("[[%s]]",input{1}.tag); % TODO: make sure this string is unique across inputs and outputs
    boutiques_input.list          = false;
    if(isIn(fieldnames(input{1}),"num") )
      % If input has a field called "num" then it is a list
      boutiques_input.list                 = true;
      if(columns(input{1}.num)!=2)
        error("'num' field does not have 2 columns") % This should never happen
      endif
      boutiques_input.("min-list-entries") = input{1}.num(1);
      max = input{1}.num(2);
      if(max!=Inf)
        boutiques_input.("max-list-entries") = max;
      endif
    endif
    boutiques_input.optional      = false; % FIXME: are there optional parameters in SPM?
  
    % TODO default value? 
    % TODO dependencies among inputs? Is that what is defined by the "tree" of parameters mentioned in Boutiques' Github #64?
  
    % Add input to the tool descriptor
    boutiques_desc.inputs{ninputs} = boutiques_input;
  endfor % for input = object.val
    
  % Set output fields
  boutiques_desc.("output-files") = cell(0,0);
  % TODO where are the outputs defined?
  
%  boutiques_desc
  json_opts.ParseLogical = 1;
  json_opts.FileName     = json_file_name;
  savejson('',boutiques_desc,json_opts);
end