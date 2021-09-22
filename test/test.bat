for %%f in (%*) do (
    git clone -–recurse-submodules https://%GIT_CREDS%@github.com/metanorma/mn-samples-%%f.git
    pushd mn-samples-%%f
    call rm Gemfile
    call metanorma site generate . -c metanorma.yml --agree-to-terms
    if %ERRORLEVEL% GEQ 1 EXIT /B 1
    popd
)