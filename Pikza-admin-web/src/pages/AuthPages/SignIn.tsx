import PizzaSignInForm from "@/components/auth/PizzaSignInForm";
import PageMeta from "@/components/common/PageMeta";
import AuthLayout from "./AuthPageLayout";

export default function SignIn() {
  return (
    <>
      <PageMeta
        title="Acceso | Mamma Pizza"
        description="Acceso para administradores y repartidores de Mamma Pizza"
      />
      <AuthLayout>
        <PizzaSignInForm />
      </AuthLayout>
    </>
  );
}
