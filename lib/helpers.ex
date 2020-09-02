defmodule DateHelpers do
    def format_date(date) do
        case Calendar.Strftime.strftime(date, "%d %B %Y") do
            {:ok, formatted } -> formatted
            _ -> throw Kernel.inspect(date) <> "formatting error"
        end
    end
end