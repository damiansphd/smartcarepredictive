function [selectdays, focusoption] = setFocusDays()

% setFocusDays - sets an array containing the subset of days to focus on

fprintf('Select focus days\n');
fprintf('-----------------\n');
fprintf('1: Days 1-10\n');
fprintf('2: Days 2, 5, 8\n');
fprintf('3: Days 3, 6, 9\n');
focusoption = input('Choose study to run for: ');

if focusoption > 3
    fprintf('Invalid choice\n');
    return;
end
if isequal(focusoption,'')
    fprintf('Invalid choice\n');
    return;
end
fprintf('\n');

if focusoption == 1
    selectdays = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
elseif focusoption == 2
    selectdays = [2, 5, 8];
elseif focusoption == 3
    selectdays = [3, 6, 9];
else
    fprintf('Invalid choice\n');
    return;
end

end

