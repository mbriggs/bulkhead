import { Controller } from "@hotwired/stimulus";
import { Datepicker } from "air-datepicker";

const locale = {
  days: [
    "Sunday",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
  ],
  daysShort: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
  daysMin: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"],
  months: [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ],
  monthsShort: [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ],
  today: "Today",
  clear: "Clear",
  dateFormat: "MM/dd/yyyy",
  firstDay: 0,
};

// Connects to data-controller="datepicker"
export default class extends Controller {
  connect() {
    this.datepicker = new Datepicker(this.element, {
      locale,
      autoClose: true,
      buttons: [
        {
          content: (dp) => dp.locale.today,
          onClick: (dp) => {
            const today = new Date();
            dp.setViewDate(today);
            dp.selectDate(today);
          },
        },
        "clear",
      ],
    });
  }

  disconnect() {
    this.datepicker.destroy();
  }
}
