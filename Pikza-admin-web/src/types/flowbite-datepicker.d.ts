declare module "flowbite-datepicker/Datepicker" {
  export type DatepickerLocale = {
    days: string[];
    daysShort: string[];
    daysMin: string[];
    months: string[];
    monthsShort: string[];
    today: string;
    monthsTitle?: string;
    clear?: string;
    weekStart?: number;
    format?: string;
  };

  export type DatepickerOptions = {
    autohide?: boolean;
    clearBtn?: boolean;
    format?: string;
    language?: string;
    orientation?: string;
    todayBtn?: boolean;
    todayBtnMode?: number;
    todayHighlight?: boolean;
    weekStart?: number;
  };

  export default class Datepicker {
    static locales: Record<string, DatepickerLocale>;

    constructor(element: HTMLInputElement, options?: DatepickerOptions);
    destroy(): Datepicker;
    getDate(): Date | Date[] | undefined;
    setDate(date: Date): void;
  }
}