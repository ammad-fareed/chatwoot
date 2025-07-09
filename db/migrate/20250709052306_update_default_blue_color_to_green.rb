class UpdateDefaultBlueColorToGreen < ActiveRecord::Migration[7.1]
  def change
    change_column_default :channel_web_widgets, :widget_color, '#3a6766'
    change_column_default :labels, :color, '#3a6766'
  end
end
